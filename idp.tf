// This hooks into our identity provider

data "http" "shib_idp_metadata" {
  url = "https://shib.bu.edu/idp/shibboleth"
}


resource "aws_iam_saml_provider" "default" {
  name = "shib.bu.edu"
  saml_metadata_document = "${data.http.shib_idp_metadata.body}"
}

resource "aws_cognito_identity_pool" "shib" {
  identity_pool_name = "BU IdP"
  allow_unauthenticated_identities = false

  /* cognito_identity_providers {
  } */

  saml_provider_arns = [ "${aws_iam_saml_provider.default.arn}" ]
}

// S3 buckets
// based on Static Website Hosting on 
// https://www.terraform.io/docs/providers/aws/r/s3_bucket.html

resource "aws_s3_bucket" "private" {
  bucket = "rexden-private-bucket"
  acl = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"

    routing_rules = <<EOF
[{
  "Condition": {
    "KeyPrefixEquals": "docs/"
  },
  "Redirect": {
    "ReplaceKeyPrefixWith": "documents/"
  }
}]
EOF
  }

  tags {
    Name = "Test Website Bucket"
  }
}

// sample default web page
resource "aws_s3_bucket_object" "object" {
  bucket = "${aws_s3_bucket.private.id}"
  key = "index.html"
  content = "<html><body><h1>Hello, World</h1></body></html>"
  content_type = "text/html"
}

// Bucket policy
// https://www.terraform.io/docs/providers/aws/r/s3_bucket_policy.html
// for the CloudFront part
// https://www.terraform.io/docs/providers/aws/r/cloudfront_origin_access_identity.html
//

resource "aws_cloudfront_origin_access_identity" "private" {
  comment = "Private access to bucket"
}

data "aws_iam_policy_document" "private_s3_bucket" {
  statement {
    actions = [ "s3:GetObject" ]
    resources = [ "${aws_s3_bucket.private.arn}/*" ]

    principals {
      type = "AWS"
      identifiers = [ "${aws_cloudfront_origin_access_identity.private.iam_arn}" ]
    }
  }
}


resource "aws_s3_bucket_policy" "private" {
  bucket = "${aws_s3_bucket.private.id}"
  policy = "${data.aws_iam_policy_document.private_s3_bucket.json}"
}

// CloudFront
// https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html

locals {
  private_s3_origin_id = "PrivateS3Origin"
}

resource "aws_cloudfront_distribution" "private" {
  origin {
    domain_name = "${aws_s3_bucket.private.bucket_regional_domain_name}"
    origin_id = "${local.private_s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.private.cloudfront_access_identity_path}"
    }
  }

  enabled = true
  comment = "Test private CloudFront"
  default_root_object = "index.html"

  aliases = [ "private.static.rexden.us" ]

  default_cache_behavior {
    allowed_methods = [ "GET", "HEAD" ]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = "${local.private_s3_origin_id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 30
    max_ttl = 60
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = [ "US", "CA", "GB", "DE" ]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


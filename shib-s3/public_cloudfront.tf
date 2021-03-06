// Bucket policy
// https://www.terraform.io/docs/providers/aws/r/s3_bucket_policy.html
// for the CloudFront part
// https://www.terraform.io/docs/providers/aws/r/cloudfront_origin_access_identity.html
//

resource "aws_cloudfront_origin_access_identity" "public" {
  comment = "Public access to bucket"
}

// CloudFront
// https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html

locals {
  public_s3_origin_id = "Public3Origin"
}

resource "aws_cloudfront_distribution" "public" {
  origin {
    domain_name = "${aws_s3_bucket.public.bucket_regional_domain_name}"
    origin_id = "${local.public_s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.public.cloudfront_access_identity_path}"
    }
  }

  enabled = true
  comment = "Test public CloudFront"
  default_root_object = "index.html"

  aliases = [ "public.static.rexden.us" ]

  default_cache_behavior {
    allowed_methods = [ "GET", "HEAD" ]
    cached_methods = [ "GET", "HEAD" ]
    target_origin_id = "${local.public_s3_origin_id}"

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


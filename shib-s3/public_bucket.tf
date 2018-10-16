// S3 buckets
// based on Static Website Hosting on 
// https://www.terraform.io/docs/providers/aws/r/s3_bucket.html

resource "aws_s3_bucket" "public" {
  bucket = "rexden-public-bucket"
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
    Name = "Test Public Website Bucket"
  }
}

// sample default web page
 resource "aws_s3_bucket_object" "object" {
  bucket = "${aws_s3_bucket.public.id}"
  key = "index.html"
  content = "<html><body><h1>Hello, World</h1></body></html>"
  content_type = "text/html"
} 

// Bucket policy
// https://www.terraform.io/docs/providers/aws/r/s3_bucket_policy.html
// for the CloudFront part
// https://www.terraform.io/docs/providers/aws/r/cloudfront_origin_access_identity.html
//

data "aws_iam_policy_document" "public_s3_bucket" {
  //statement {
    //actions = [ "s3:GetObject" ]
    //resources = [ "${aws_s3_bucket.public.arn}" ]
    //principals {
    //  type = "AWS"
    //  identifiers = [ "${aws_cloudfront_origin_access_identity.public.iam_arn}" ]
    //}
  //}

  statement {
    actions = [ "s3:GetObject" ]
    resources = [ "${aws_s3_bucket.public.arn}/*" ]

    principals {
      type = "AWS"
      identifiers = [ "${aws_cloudfront_origin_access_identity.public.iam_arn}" ]
    }
  }
}


resource "aws_s3_bucket_policy" "public" {
  bucket = "${aws_s3_bucket.public.id}"
  policy = "${data.aws_iam_policy_document.public_s3_bucket.json}"
}

// CloudFront
// https://www.terraform.io/docs/providers/aws/r/cloudfront_distribution.html


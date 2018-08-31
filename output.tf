//output "ip" {
//  value = "${aws_instance.shibidp.private_ip}"
//}
output "private_address" {
  value = "${aws_cloudfront_distribution.private.domain_name}"
}

output "bucket_address" {
  value = "${aws_s3_bucket.private.bucket_domain_name}"
}

output "bucket_regional_address" {
  value = "${aws_s3_bucket.private.bucket_regional_domain_name}"
}

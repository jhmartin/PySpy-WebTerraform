resource "aws_s3_bucket" "pyspy_static" {
  bucket_prefix = "pyspy-"
  acl           = "private"

  # Additional configurations like versioning, logging, etc. can be added here
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "pyspy-static"
  description                       = "Origin Access Control for my S3 bucket"
  origin_access_control_origin_type = "s3"

  signing_behavior = "always"
  signing_protocol = "sigv4"

  provider = aws.ue1
}

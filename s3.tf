resource "aws_s3_bucket" "pyspy_static" {
  bucket_prefix = "pyspy-"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "pyspy-static"
  description                       = "Origin Access Control for my S3 bucket"
  origin_access_control_origin_type = "s3"

  signing_behavior = "always"
  signing_protocol = "sigv4"

  provider = aws.ue1
}

resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.pyspy_static.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access.json
}

data "aws_iam_policy_document" "cloudfront_oac_access" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.pyspy_static.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.distribution.arn]
    }
  }
}

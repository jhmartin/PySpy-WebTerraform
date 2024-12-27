resource "aws_s3_bucket" "cloudfront_logging" {
  bucket_prefix = "pyspy-cf"
  provider      = aws.ue1
}

resource "aws_s3_bucket_policy" "cloudfront" {
  bucket = aws_s3_bucket.pyspy_static.id
  policy = data.aws_iam_policy_document.cloudfront_logging.json
}

data "aws_iam_policy_document" "cloudfront_logging" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl"
    ]

    resources = [
      aws_s3_bucket.cloudfront_logging.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:delivery-source*"]
    }
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resource = ["${aws_s3_bucket.cloudfront_logging.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}

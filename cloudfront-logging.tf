data "aws_canonical_user_id" "current" {}
data "aws_cloudfront_log_delivery_canonical_user_id" "cf" {}


resource "aws_s3_bucket" "cloudfront_logging" {
  bucket_prefix = "pyspy-cf"
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id

  access_control_policy {
    grant {
      grantee {
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.cf.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logging]
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_expiration" {
  bucket = aws_s3_bucket.cloudfront_logging.id

  rule {
    id = "Expiration"

    filter {}

    status = "Enabled"

    expiration {
      days = 30
    }

  }
}

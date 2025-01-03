# The web backend always fetches by user id. AWS has a free tier for DDB so we'll use that.

resource "aws_dynamodb_table" "pyspy_intel" {
  name           = "pyspy-intel" # Set the name of your DynamoDB table
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "character_id" # Specify your table's hash key

  point_in_time_recovery {
    # Table is <1GB so this is not that expensive
    enabled = true
  }

  attribute {
    name = "character_id"
    type = "N" # 'S' for string, 'N' for number, 'B' for binary
  }

  import_table {
    input_compression_type = "NONE"
    input_format           = "DYNAMODB_JSON"

    s3_bucket_source {
      bucket     = "pyspy-upload"
      key_prefix = "intel4"
    }

  }
}

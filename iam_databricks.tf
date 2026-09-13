# IAM user Databricks uses to write intel records into the pyspyv3-intel table.

resource "aws_iam_user" "databricks_pyspyv3" {
  name                 = "pyspy3-databricks-writer"
  permissions_boundary = data.aws_iam_policy.pb.arn
}

resource "aws_iam_access_key" "databricks_pyspyv3" {
  user = aws_iam_user.databricks_pyspyv3.name
}

data "aws_iam_policy_document" "databricks_pyspyv3_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DescribeTable",
    ]
    resources = [aws_dynamodb_table.pyspyv3_intel.arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.region]
    }
  }
}

resource "aws_iam_user_policy" "databricks_pyspyv3_dynamodb" {
  name   = "pyspyv3-databricks-dynamodb-write"
  user   = aws_iam_user.databricks_pyspyv3.name
  policy = data.aws_iam_policy_document.databricks_pyspyv3_dynamodb.json
}

output "databricks_pyspyv3_access_key_id" {
  value = aws_iam_access_key.databricks_pyspyv3.id
}

output "databricks_pyspyv3_secret_access_key" {
  value     = aws_iam_access_key.databricks_pyspyv3.secret
  sensitive = true
}

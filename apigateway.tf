resource "aws_api_gateway_rest_api" "pyspy" {
  name        = "pyspy"
  description = "API Gateway to trigger the pyspy lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

}

resource "aws_api_gateway_resource" "pyspy" {
  rest_api_id = aws_api_gateway_rest_api.pyspy.id
  parent_id   = aws_api_gateway_rest_api.pyspy.root_resource_id
  path_part   = "character_intel"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.pyspy.id
  resource_id   = aws_api_gateway_resource.pyspy.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.pyspy.id
  resource_id             = aws_api_gateway_resource.pyspy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.html_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.pyspy.id
  resource_id = aws_api_gateway_resource.pyspy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.pyspy.id
  resource_id = aws_api_gateway_resource.pyspy.id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.pyspy.id
  stage_name  = "stg" # replace with aws_api_gateway_stage
}

data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = "pyspy.py"
  output_path = "pyspy.zip"
}

resource "aws_lambda_function" "html_lambda" {
  filename         = "pyspy.zip"
  function_name    = "pyspy-web"
  role             = aws_iam_role.lambda_role.arn
  handler          = "pyspy.lambda_handler"
  runtime          = "python3.13"
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
}

data "aws_iam_policy" "pb" {
  name = "pyspy-pb"
}

resource "aws_iam_role" "lambda_role" {
  name                 = "lambda-role"
  permissions_boundary = data.aws_iam_policy.pb.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_ddb" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.html_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.pyspy.execution_arn}/*/*/*"
}

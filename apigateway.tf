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
  type                    = "AWS_PROXY"
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
}

resource "aws_api_gateway_stage" "devstage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.pyspy.id
  stage_name    = "dev"
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


  environment {
    variables = {
      table = aws_dynamodb_table.pyspy_intel.id
    }
  }
}

data "aws_iam_policy" "pb" {
  name = "pyspy-pb"
}

resource "aws_iam_role" "lambda_role" {
  name                 = "pyspy-lambda-role"
  permissions_boundary = data.aws_iam_policy.pb.arn

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
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

output "dev_invoke_url" {
  value = aws_api_gateway_stage.devstage.invoke_url
}

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

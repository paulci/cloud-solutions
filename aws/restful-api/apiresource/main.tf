data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_api_gateway_resource" "modularresource" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = var.resource_path
}

resource "aws_api_gateway_method" "modularresourcemethod" {
  rest_api_id      = var.rest_api_id
  resource_id      = aws_api_gateway_resource.modularresource.id
  http_method      = var.http_method
  authorization    = var.authorization
  authorizer_id    = var.authorizer_id
  api_key_required = false
}

resource "aws_api_gateway_integration" "lambdaintegration" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.modularresource.id
  http_method             = aws_api_gateway_method.modularresourcemethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.uri
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.rest_api_id}/*/${aws_api_gateway_method.modularresourcemethod.http_method}${aws_api_gateway_resource.modularresource.path}"
}

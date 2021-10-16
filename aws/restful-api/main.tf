resource "aws_api_gateway_rest_api" "modularapi" {
  name = var.api_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "modularresource" {
  rest_api_id = aws_api_gateway_rest_api.modularapi.id
  parent_id   = aws_api_gateway_rest_api.modularapi.root_resource_id
  path_part   = var.resource_path
}

resource "aws_api_gateway_method" "modularresourcemethod" {
  rest_api_id      = aws_api_gateway_rest_api.modularapi.id
  resource_id      = aws_api_gateway_resource.modularresource.id
  http_method      = "GET"
  authorization    = "CUSTOM" # CUSTOM for lambda
  authorizer_id    = aws_api_gateway_authorizer.demo.id
  api_key_required = false
}

resource "aws_api_gateway_integration" "lambdaintegration" {
  rest_api_id             = aws_api_gateway_rest_api.modularapi.id
  resource_id             = aws_api_gateway_resource.modularresource.id
  http_method             = aws_api_gateway_method.modularresourcemethod.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello.invoke_arn
}

resource "aws_api_gateway_authorizer" "demo" {
  name                             = "demo"
  rest_api_id                      = aws_api_gateway_rest_api.modularapi.id
  authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
  authorizer_result_ttl_in_seconds = 60
  authorizer_credentials           = aws_iam_role.invocation_role.arn
  identity_source                  = "method.request.header.x-api-key"
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = aws_iam_role.invocation_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${aws_lambda_function.authorizer.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda" {
  name = "demo-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "mypythonauth"
  filename         = "auth-function.zip"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.auth.output_base64sha256
}

resource "aws_lambda_function" "hello" {
  function_name    = "web"
  filename         = "hello-function.zip"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.web.output_base64sha256
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-1:198653053291:${aws_api_gateway_rest_api.modularapi.id}/*/${aws_api_gateway_method.modularresourcemethod.http_method}${aws_api_gateway_resource.modularresource.path}"
}

data "archive_file" "auth" {
  type        = "zip"
  source_dir  = "auth-function"
  output_path = "auth-function.zip"
  excludes    = ["auth-function/requirements.txt"]
}

data "archive_file" "web" {
  type        = "zip"
  source_file = "hello-function/lambda_function.py"
  output_path = "hello-function.zip"
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

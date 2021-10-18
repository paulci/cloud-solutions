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
  authorization    = "CUSTOM"
  authorizer_id    = aws_api_gateway_authorizer.python_jwt_auth.id
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

resource "aws_api_gateway_authorizer" "python_jwt_auth" {
  name                             = "python_jwt_auth"
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

resource "aws_iam_policy" "secrets_policy" {
  name = "default"


  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "secretsmanager:GetSecretValue",
        "Effect" : "Allow",
        "Resource" : "${aws_secretsmanager_secret.jwtkey.arn}"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_execution" {
  name = "api-lambda-execution"

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
  role             = aws_iam_role.lambda_execution.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.8"
  source_code_hash = data.archive_file.auth.output_base64sha256
  environment {
    variables = {
      jwt_secret_arn = aws_secretsmanager_secret.jwtkey.arn
      region         = data.aws_region.current.name
    }
  }
}

resource "aws_lambda_function" "hello" {
  function_name    = "web"
  filename         = "hello-function.zip"
  role             = aws_iam_role.lambda_execution.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = data.archive_file.web.output_base64sha256
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.modularapi.id}/*/${aws_api_gateway_method.modularresourcemethod.http_method}${aws_api_gateway_resource.modularresource.path}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "archive_file" "auth" {
  type        = "zip"
  source_dir  = "auth-function"
  output_path = "auth-function.zip"
  excludes    = ["requirements.txt"]
}

data "archive_file" "web" {
  type        = "zip"
  source_file = "hello-function/lambda_function.py"
  output_path = "hello-function.zip"
}

resource "aws_iam_role_policy_attachment" "cloudwatch-lambda-attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "secrets-lambda-attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "aws_secretsmanager_secret" "jwtkey" {
  name        = "JWTSecret001"
  description = "JWT Secret for Lambda Authorizer"
}

# resource "aws_secretsmanager_secret_version" "jwtkey" {
#   secret_id     = aws_secretsmanager_secret.jwtkey.id
#   secret_string = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYW1lIjoicGF1bCJ9.dnFzd_5kMxN41MqahA0X1ZzvMnpEioPDGjDL_xcqd5Y"
# }

resource "aws_api_gateway_deployment" "v1" {
  rest_api_id = aws_api_gateway_rest_api.modularapi.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.modularresource.id,
      aws_api_gateway_method.modularresourcemethod.id,
      aws_api_gateway_integration.lambdaintegration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "v1" {
  deployment_id = aws_api_gateway_deployment.v1.id
  rest_api_id   = aws_api_gateway_rest_api.modularapi.id
  stage_name    = "v1"
}

resource "aws_wafv2_web_acl_association" "v1" {
  resource_arn = aws_api_gateway_stage.v1.arn
  web_acl_arn  = aws_wafv2_web_acl.example.arn
}

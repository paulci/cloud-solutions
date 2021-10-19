data "aws_region" "current" {}

resource "aws_api_gateway_rest_api" "modularapi" {
  name = var.api_name
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

module "authfunction" {
  source = "./function"

  function_name = "pythonauth"
  package       = "auth-function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment_variables = {
    jwt_secret_arn = aws_secretsmanager_secret.jwtkey.arn
    region         = data.aws_region.current.name
  }
  function_source_dir = "auth-function"
  package_excludes    = ["requirements.txt"]
}

module "webfunction" {
  source = "./function"

  function_name = "web"
  package       = "hello-function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment_variables = {
    region = data.aws_region.current.name
  }
  function_source_dir = "hello-function"
}

module "pythonauthorizer" {
  source = "./authorizer"

  auth_name      = "pythonjwtauth"
  rest_api_id    = aws_api_gateway_rest_api.modularapi.id
  authorizer_uri = module.authfunction.function_invoke_arn
  resource       = module.authfunction.function_arn
}

module "helloresource" {
  source = "./apiresource"

  rest_api_id   = aws_api_gateway_rest_api.modularapi.id
  parent_id     = aws_api_gateway_rest_api.modularapi.root_resource_id
  resource_path = "hello"
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = module.pythonauthorizer.authorizer_id
  uri           = module.webfunction.function_invoke_arn
  function_name = module.webfunction.function_name
}

resource "aws_iam_policy" "secrets_policy" {
  name = "apigw_lambda_secrets_access"
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

resource "aws_iam_role_policy_attachment" "secrets-lambda-attach" {
  role       = module.authfunction.execution_role_name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

resource "aws_secretsmanager_secret" "jwtkey" {
  name        = "JWTSecret001"
  description = "JWT Secret for Lambda Authorizer"
}

resource "aws_secretsmanager_secret_version" "jwtkey" {
  secret_id     = aws_secretsmanager_secret.jwtkey.id
  secret_string = var.jwtsecret
}

resource "aws_api_gateway_deployment" "v1" {
  rest_api_id = aws_api_gateway_rest_api.modularapi.id

  triggers = {
    redeployment = sha1(jsonencode([
      module.helloresource.resource_id,
      module.helloresource.method_id,
      module.helloresource.integration_id,
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
  web_acl_arn  = aws_wafv2_web_acl.managedrules-acl.arn
}

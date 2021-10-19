resource "aws_api_gateway_authorizer" "lambdaauth" {
  name                             = var.auth_name
  rest_api_id                      = var.rest_api_id
  authorizer_uri                   = var.authorizer_uri
  authorizer_result_ttl_in_seconds = 60
  authorizer_credentials           = aws_iam_role.invocation_role.arn
  identity_source                  = "method.request.header.x-api-key"
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = jsonencode(
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
})
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "authorizer_invocation"
  role = aws_iam_role.invocation_role.id

  policy = jsonencode(
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": "${var.resource}"
    }
  ]
})
}

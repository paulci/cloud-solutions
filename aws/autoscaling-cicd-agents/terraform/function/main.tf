# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_role" "lambda_execution" {
  name = "${var.function_name}-execution"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
}

resource "aws_lambda_function" "function" {
  function_name    = var.function_name
  filename         = var.package
  role             = aws_iam_role.lambda_execution.arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.function_timeout_seconds
  source_code_hash = data.archive_file.package.output_base64sha256
  environment {
    variables = var.environment_variables
  }
}

data "archive_file" "package" {
  type        = "zip"
  source_dir  = var.function_source_dir
  output_path = var.package
  excludes    = var.package_excludes
}

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret" "adopat" {
  name        = "ADOPAT001"
  description = "PAT scoped for retrieving ADO pool data"
}

resource "aws_iam_policy" "ado_queue_metrics" {
  name = "ado_queue_execution_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "secretsmanager:GetSecretValue",
        "Effect" : "Allow",
        "Resource" : "${aws_secretsmanager_secret.adopat.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : "cloudwatch:PutMetricData",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "cloudwatch:namespace" : "ADOAgentQueue"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${module.ado_queue_function.function_name}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ado_queue_metrics" {
  role       = module.ado_queue_function.execution_role_name
  policy_arn = aws_iam_policy.ado_queue_metrics.arn
}

module "ado_queue_function" {
  source = "./function"

  function_name = "ado_queue_metrics"
  package       = "ado-function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment_variables = {
    ado_org_name   = var.ado_org_name
    ado_secret_arn = aws_secretsmanager_secret.adopat.arn
    region         = data.aws_region.current.name
  }
  function_source_dir = "../src/ado_queue_function"
  package_excludes = [
    "requirements.txt",
    "dev-requirements.txt",
    "tests",
    "__pycache__",
    ".coverage",
    ".pytest_cache"
  ]
}

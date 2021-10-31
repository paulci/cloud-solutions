# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ADO Queue Monitoring Resources
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

# ECS Service Monitoring Resourcs
resource "aws_iam_policy" "agent_service_metrics" {
  name = "service_metrics_execution_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "cloudwatch:GetMetricStatistics",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "cloudwatch:namespace" : "${var.agent_cw_namespace}"
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
        "Resource" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${module.service_metrics_function.function_name}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "agent_service_metrics" {
  role       = module.service_metrics_function.execution_role_name
  policy_arn = aws_iam_policy.agent_service_metrics.arn
}

module "service_metrics_function" {
  source = "./function"

  function_name = "agent_service_metrics"
  package       = "agent-function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment_variables = {
    cw_namespace = var.agent_cw_namespace
    cw_metric    = var.agent_cw_metric
    region       = data.aws_region.current.name
  }
  function_source_dir = "../src/service_metrics_function"
  package_excludes = [
    "requirements.txt",
    "dev-requirements.txt",
    "tests",
    "__pycache__",
    ".coverage",
    ".pytest_cache"
  ]
}

# ECS Cluster, Task and IAM
resource "aws_ecr_repository" "adoagent" {
  name                 = "adoagent"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

module "queue_001_cluster" {
  source = "./ecs"

  ado_org_name       = var.ado_org_name
  agent_cluster_name = "queue_001_cluster"
  agent_image        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/adoagent:latest"
  ado_pat_secret     = var.ado_pat
}

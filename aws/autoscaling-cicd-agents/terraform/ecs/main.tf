# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "agent_data" {
  description             = "The AWS Key Management Service key ID to encrypt the data between the local client and the container"
  deletion_window_in_days = 7
}

resource "aws_cloudwatch_log_group" "ado_agent_logs" {
  name = var.agent_cluster_name
}

resource "aws_ssm_parameter" "ado_pat" {
  name        = "${var.agent_cluster_name}-PAT"
  description = "Personal Access Token scoped to manage Agent Pools"
  type        = "SecureString"
  value       = var.ado_pat_secret
}

resource "aws_ecs_cluster" "ado_agent_pool" {
  name = var.agent_cluster_name

  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.agent_data.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.ado_agent_logs.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "ado_agent_task" {
  family = "ado_agent_task"
  container_definitions = jsonencode([
    {
      name      = "adoagent"
      image     = var.agent_image
      cpu       = 10
      memory    = 512
      essential = true
      "environment" : [
        { "name" : "AZP_URL", "value" : "https://dev.azure.com/${var.ado_org_name}" }
      ]
      "secrets" : [
        { "name" : "AZP_TOKEN", "valueFrom" : "${aws_ssm_parameter.ado_pat.arn}" }
      ]
    }
  ])
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.agent_task_role.arn
}

resource "aws_iam_role" "agent_task_role" {
  name = "adoagentexecutionrole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "agent_task_execution_policy" {
  name = "agent_task_execution_policy"
  role = aws_iam_role.agent_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters*",
        ]
        Effect   = "Allow"
        Resource = "${aws_ssm_parameter.ado_pat.arn}"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "${aws_cloudwatch_log_group.ado_agent_logs.arn}:*"
      }
    ]
  })
}

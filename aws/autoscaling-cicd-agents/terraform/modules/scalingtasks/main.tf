# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

#####################################################################
# ECS Resources                                                     #
#####################################################################
resource "aws_ecr_repository" "adoagent" {
  name                 = var.image_name
  image_tag_mutability = var.image_tag_mutability
  image_scanning_configuration {
    scan_on_push = var.image_scan_on_push
  }
}
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
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "ado_agent_task" {
  family = var.state_machine_name
  container_definitions = jsonencode([
    {
      name      = "adoagent"
      image     = var.agent_image
      cpu       = 10
      memory    = 512
      essential = true
      "environment" : [
        { "name" : "AZP_URL", "value" : "https://dev.azure.com/${var.ado_org_name}" },
        { "name" : "AZP_POOL", "value" : "${var.ado_pool_name}" }
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
  name = "${var.state_machine_name}_ecs_execution_role"
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
          "ecr:GetAuthorizationToken"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        "Resource" : "${aws_ecr_repository.adoagent.arn}"
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

#####################################################################
# State Machine Resources                                           #
#####################################################################
resource "aws_cloudwatch_log_group" "scaling_workflow" {
  name              = var.state_machine_name
  retention_in_days = 7
}

resource "aws_sfn_state_machine" "scaling_queue" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.sfn_execution.arn
  type     = "EXPRESS"

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.scaling_workflow.arn}:*"
    include_execution_data = var.workflow_logging_enabled
    level                  = var.workflow_logging_enabled == true ? "ALL" : "OFF"
  }

  definition = jsonencode({
    "Comment" : "Scaling ADO Agents",
    "StartAt" : "Gather Metrics",
    "States" : {
      "Gather Metrics" : {
        "Type" : "Parallel",
        "Branches" : [
          {
            "StartAt" : "ADO Queue & Agent Metrics",
            "States" : {
              "ADO Queue & Agent Metrics" : {
                "Type" : "Task",
                "Resource" : "arn:aws:states:::lambda:invoke",
                "OutputPath" : "$.Payload",
                "Parameters" : {
                  "Payload.$" : "$",
                  "FunctionName" : "${var.ado_queue_function_arn}:$LATEST"
                },
                "Retry" : [
                  {
                    "ErrorEquals" : [
                      "Lambda.ServiceException",
                      "Lambda.AWSLambdaException",
                      "Lambda.SdkClientException"
                    ],
                    "IntervalSeconds" : 2,
                    "MaxAttempts" : 6,
                    "BackoffRate" : 2
                  }
                ],
                "End" : true
              }
            }
          },
          {
            "StartAt" : "Running ADO Agent Containers",
            "States" : {
              "Running ADO Agent Containers" : {
                "Type" : "Task",
                "End" : true,
                "Parameters" : {
                  "EndTime" : "2021-06-30T19:00:00Z",
                  "MetricName" : "TaskCount",
                  "Dimensions" : [{
                    "Name" : "ClusterName",
                    "Value" : "${var.agent_cluster_name}"
                  }]
                  "Namespace" : "ECS/ContainerInsights",
                  "Period" : 360,
                  "StartTime" : "2021-06-30T12:00:00Z",
                  "Statistics" : [
                    "Maximum"
                  ]
                },
                "Resource" : "arn:aws:states:::aws-sdk:cloudwatch:getMetricStatistics"
              }
            }
          }
        ],
        "Next" : "Transform Inputs"
      },
      "Transform Inputs" : {
        "Type" : "Pass",
        "Next" : "Scaling Decider",
        "Parameters" : {
          "ado_waiting_jobs.$" : "$[0].waiting_jobs",
          "ado_unassigned_agents.$" : "$[0].idle_agents",
          "pool_id.$" : "$[0].ado_pool_id"
        }
      },
      "Scaling Decider" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::lambda:invoke",
        "Parameters" : {
          "Payload.$" : "$",
          "FunctionName" : "${var.decider_function}:$LATEST"
        },
        "Retry" : [
          {
            "ErrorEquals" : [
              "Lambda.ServiceException",
              "Lambda.AWSLambdaException",
              "Lambda.SdkClientException"
            ],
            "IntervalSeconds" : 2,
            "MaxAttempts" : 6,
            "BackoffRate" : 2
          }
        ],
        "Next" : "Scaling Decision",
        "ResultPath" : "$.Decider"
      },
      "Scaling Decision" : {
        "Type" : "Choice",
        "Choices" : [
          {
            "Variable" : "$.Decider.Payload.decision",
            "StringMatches" : "scale-out",
            "Next" : "ECS RunTask"
          },
          {
            "Variable" : "$.Decider.Payload.decision",
            "StringMatches" : "scale-in",
            "Next" : "ListTasks"
          }
        ],
        "Default" : "Success"
      },
      "ListTasks" : {
        "Type" : "Task",
        "Next" : "DescribeTasks",
        "ResultPath" : "$.result"
        "Parameters" : {
          "Cluster" : "${aws_ecs_cluster.ado_agent_pool.arn}",
          "Family" : "${var.state_machine_name}",
          "DesiredStatus" : "RUNNING"
        },
        "Resource" : "arn:aws:states:::aws-sdk:ecs:listTasks"
      },
      "DescribeTasks" : {
        "Type" : "Task",
        "Next" : "Map",
        "Parameters" : {
          "Cluster" : "${aws_ecs_cluster.ado_agent_pool.arn}",
          "Tasks.$" : "$.result.TaskArns"
        },
        "ResultPath" : "$.describe_input",
        "Resource" : "arn:aws:states:::aws-sdk:ecs:describeTasks"
      },
      "Map" : {
        "Iterator" : {
          "StartAt" : "Deregister Agents",
          "States" : {
            "Deregister Agents" : {
              "End" : true,
              "OutputPath" : "$.Payload",
              "Parameters" : {
                "FunctionName" : "${var.ado_deregister_function_arn}:$LATEST",
                "Payload.$" : "$"
              },
              "Resource" : "arn:aws:states:::lambda:invoke",
              "Retry" : [
                {
                  "BackoffRate" : 2,
                  "ErrorEquals" : [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException"
                  ],
                  "IntervalSeconds" : 2,
                  "MaxAttempts" : 6
                }
              ],
              "Type" : "Task"
            }
          }
        },
        "Next" : "Success",
        "Type" : "Map",
        "ItemsPath" : "$.describe_input.Tasks",
        "Parameters" : {
          "Attachments.$" : "$$.Map.Item.Value"
          "pool_id.$" : "$.pool_id"
        }
      },
      "ECS RunTask" : {
        "Type" : "Task",
        "Resource" : "arn:aws:states:::ecs:runTask",
        "Parameters" : {
          "NetworkConfiguration" : {
            "AwsvpcConfiguration" : {
              "Subnets" : [
                "${var.subnet}"
              ],
              "SecurityGroups" : [
                "${var.security_group}"
              ],
              "AssignPublicIp" : "${var.assign_public_ip}"
            }
          },
          "Count.$" : "$.Decider.Payload.delta",
          "LaunchType" : "FARGATE",
          "Cluster" : "${aws_ecs_cluster.ado_agent_pool.arn}",
          "TaskDefinition" : "${aws_ecs_task_definition.ado_agent_task.arn}"
        },
        "Next" : "Success"
      },
      "Success" : {
        "Type" : "Succeed"
      }
    }
  })
}

resource "aws_iam_role" "sfn_execution" {
  name = "${var.state_machine_name}_state_machine_execution"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "states.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
}

resource "aws_iam_role_policy" "workflow_execution_policy" {
  name = "workflow_execution_policy"
  role = aws_iam_role.sfn_execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:GetMetricStatistics",
          "xray:PutTelemetryRecords",
          "logs:DescribeLogGroups",
          "lambda:InvokeFunction",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetAuthorizationToken",
          "xray:GetSamplingTargets",
          "logs:GetLogDelivery",
          "logs:ListLogDeliveries",
          "xray:PutTraceSegments",
          "logs:CreateLogDelivery",
          "logs:PutResourcePolicy",
          "logs:UpdateLogDelivery",
          "xray:GetSamplingRules",
          "ecr:BatchGetImage",
          "logs:DeleteLogDelivery",
          "logs:DescribeResourcePolicies",
          "ecr:BatchCheckLayerAvailability",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:RunTask",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

#####################################################################
#  Cloudwatch Resources                                             #
#####################################################################
resource "aws_iam_role" "cloudwatch_sfn_execution" {
  name = "${var.state_machine_name}_event_sfn_execution"

  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "events.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
  })
}

resource "aws_cloudwatch_event_rule" "ado_scaling_workflow" {
  name                = "trigger_${var.state_machine_name}_workflow"
  description         = "Populate CW with ADO Metrics and manage ECS Tasks"
  schedule_expression = "rate(2 minutes)"
}

resource "aws_cloudwatch_event_target" "sfn" {
  rule     = aws_cloudwatch_event_rule.ado_scaling_workflow.name
  arn      = aws_sfn_state_machine.scaling_queue.arn
  role_arn = aws_iam_role.cloudwatch_sfn_execution.arn
}

resource "aws_iam_role_policy" "cloudwatch_sfn_execution" {
  name = "cloudwatch_sfn_execution_policy"
  role = aws_iam_role.cloudwatch_sfn_execution.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "states:StartExecution",
        "Resource" : "${aws_sfn_state_machine.scaling_queue.arn}*"
      }
    ]
  })
}

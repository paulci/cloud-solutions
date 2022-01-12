# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# Temp Networking
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name = "tooling-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
}

resource "aws_security_group" "ado_agent" {
  name        = "ado_agent_security_group"
  description = "Allow access to poll ADO Orchestration Layer"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

#####################################################################
# Shared Function Resources                                         #
#####################################################################

# ADO Queue Monitoring
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

module "common_dependencies" {
  source = "./dependencies"

  layer_name            = "python_dependencies"
  dependency_source_dir = "../src/dependencies"
  runtimes              = ["python3.9"]
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
  layers        = [module.common_dependencies.layer_arn]
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

# Workflow Specific

module "scaling_decider_function" {
  source = "./function"

  function_name = "ecs_scaling_decider"
  package       = "decider-function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment_variables = {
    ado_org_name   = var.ado_org_name
    ado_secret_arn = aws_secretsmanager_secret.adopat.arn
    region         = data.aws_region.current.name
  }
  function_source_dir = "../src/scaling_decider_function"
  package_excludes = [
    "requirements.txt",
    "dev-requirements.txt",
    "tests",
    "__pycache__",
    ".coverage",
    ".pytest_cache"
  ]
}

resource "aws_iam_role_policy_attachment" "scaling_decider_function" {
  role       = module.scaling_decider_function.execution_role_name
  policy_arn = aws_iam_policy.ado_queue_metrics.arn
}

module "ado_deregister_agents_function" {
  source = "./function"

  function_name = "deregister_ado_agents"
  package       = "deregister-function.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  layers        = [module.common_dependencies.layer_arn]
  environment_variables = {
    ado_org_name     = var.ado_org_name
    ado_secret_arn   = aws_secretsmanager_secret.adopat.arn
    region           = data.aws_region.current.name
    assign_public_ip = var.assign_public_ip
  }
  function_source_dir = "../src/ado_deregister_agents_function"
  package_excludes = [
    "requirements.txt",
    "dev-requirements.txt",
    "tests",
    "__pycache__",
    ".coverage",
    ".pytest_cache"
  ]
}

resource "aws_iam_role_policy_attachment" "ado_deregister_agents_function" {
  role       = module.ado_deregister_agents_function.execution_role_name
  policy_arn = aws_iam_policy.ado_queue_metrics.arn
}

#####################################################################
# Scaling Agent Solutions                                           #
# Workflow, Alarms, ECS Cluster & Task Definition                   #
#                                                                   #
# To be used on a per-queue basis                                   #
#####################################################################

module "queue001_workflow" {
  source = "./scalingtasks"

  state_machine_name          = "agent_task_scaling"
  ado_queue_function_arn      = module.ado_queue_function.function_arn
  ado_queue_function_name     = module.ado_queue_function.function_name
  ado_deregister_function_arn = module.ado_deregister_agents_function.function_arn
  decider_function            = module.scaling_decider_function.function_arn
  task_family                 = "ado_agent_task"
  subnet                      = module.vpc.private_subnets[0]
  security_group              = aws_security_group.ado_agent.id
  image_name                  = "adoagent"
  image_tag_mutability        = "MUTABLE"
  image_scan_on_push          = false
  ado_org_name                = var.ado_org_name
  agent_cluster_name          = "queue_001_cluster"
  agent_image                 = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/adoagent:latest"
  ado_pat_secret              = var.ado_pat
  ado_pool_name               = var.ado_pool_name
}

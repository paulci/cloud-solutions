# WIP - AWS Autoscaling Container Build Agent Solution for Azure DevOps Services

A solution to autoscale containerised build agents, dependent on Azure DevOps Queue Sizes.  This model provides the flexibility for development teams to manage their own build dependencies and build queues, while removing the infrastructure maintenance overhead and keeping cost at a minimum.

## Current State
- Deployable Lambda function, with IAM Roles, Policy & Secret to poll Azure DevOps queue and populate Cloudwatch
    - Unit tested code, input structure validation
    - Confirmed deploylable in us-east-1 and successfully operates against test ADO Org
- Deployable linux container agents with IAM Roles, Policy & Secret to register agent with Azure DevOps queue
    - Cluster & Task Definition
    - ECR Repo
    - Docker file to build and push to ECR
- State machine to decide on scaling option
    - Triggered by Cloudwatch scheduled at pre-defined intervals
    - Scale in/out based on idle agents and queueing jobs


## Architecture
![Architecture Diagram](architecture01.png)


## State Machine
![Code and Visual Workflow Diagram](statemachine.png)


## Queue Data Function
![ADO Queue Data Retrieval Diagram](queuefunction.png)


## Deregister Agent Function
![ADO Agent Deregistration Diagram](killagents.png)

## Cost Estimate - Retail Price, checked on 14/1/2022*
### Assumptions
- Workflow executes every 2 minutes
- 100 Agent Jobs per Day
    - 5 mins per job
- Linux agent
    - 0.25 CPU
    - 512MB Memory
- Existing VPC and networking resources
- Single agent image, stored in ECR
- Free Tier included
- Hosted in us-east-1

| Service | Upfront Costs | Monthly Costs | First 12 Months | Currency | Summary |
| --- | --- | --- | --- | --- | --- |
| Step Functions - Express Workflows | 0 | 0.09 | 1.08 | USD | Duration of each workflow (3000), Memory consumed by each workflow (64 MB), Workflow requests (21600 per month) |
| AWS Lambda | 0 | 0 | 0 | USD | Architecture (x86), Architecture (x86), Number of requests (129600 per month) |
| AWS Fargate | 0 | 3.38 | 40.56 | USD | Operating system (Linux), CPU Architecture (x86), Average duration (5 minutes), Number of tasks or pods (100 per day), Amount of ephemeral storage allocated for Amazon ECS (20 GB) |
| AWS Elastic Container Registry | 0 | 1 | 12 | USD | Data transfer cost (0), Amount of data stored (10 GB per month) |
| AWS Secrets Manager | 0 | 0 | 0.51 | USD | Number of secrets (1), Average duration of each secret (30 days), Number of API calls (21600 per month) |
| AWS Parameter Store | 0 | 0 | 0 | USD | Standard parameters (1), Frequency of API interactions per parameter (30 per hour) |
| AWS Cloudwatch | 0 | 1.032 | 12.38 | USD | Number of Metrics (includes detailed and custom metrics) (2), Number of other API requests (43200) |
|  |  |  |  |  |  |
| Total | 0 | 6.01 | 72.14 | USD |  |

*These are only an estimate of potential AWS fees and doesn't include any taxes that might apply. Your actual fees depend on a variety of factors, including your actual usage of AWS services. [Do your own calculations](https://calculator.aws/#/estimate) and be prepared to accept the financial ask, before using.


## Notes:
- Workflow is triggered on a schedule.  Originally, triggered by CW event, but this method is more reliable and cost effective
- Supports multiple agent queues, configurable by json files in [config directory](src/ado_queue_function/config/)
- Max service count influenced by licenses held for self-hosted agents in Azure DevOps <insert links to dock>
- Agents are immutable and will terminate after each execution
- On scale-in, attempts are made to ensure no running jobs are terminated

## Future
- Waiter to validate task running/task stopped
- RunTask supports max 10 instances/call.  Need validation
- Queue Config managed in DynamoDB rather than flat files
- Configurable Template for task definitions
- Exceptions for Queue API call result in SNS alert
- Architecture for shared-services implementation - Using VPC Interface Endpoints and NAT gateways in a shared VPC

## Requirements

| Name | Version |
|------|---------|
| Terraform | [1.0.9]() |
| provider/archive | [2.2.0](https://registry.terraform.io/providers/hashicorp/archive) |
| provider/aws | [3.6.3](https://registry.terraform.io/providers/hashicorp/aws) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ado_org_name | Azure DevOps Service Org Name | string | n/a | Y |
| ado_pat | Personal Access Token scoped for Pool Management | string | n/a | Y |
| agent_cw_namespace | Cloudwatch namespace of ECS Service | string | n/a | Y |
| agent_cw_metric | Cloudwatch metric of ECS Service | string | n/a | Y |
| function_timeout_seconds | Lambda Timeout Configuration | number | 60 | N |


## Outputs

| Name | Description |
|------|-------------|


## Example Usage
### Deploy Resources to AWS
```
terraform apply -var 

...
Apply complete! Resources: <>

Outputs:

<>
```


## Current (WIP) Resources

| Name | Type |
|------|------|
| module.queue001_workflow.aws_cloudwatch_log_group.ado_agent_logs | [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)  |
| module.queue001_workflow.aws_ssm_parameter.ado_pat | [aws_ssm_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) |
| module.queue001_workflow.aws_iam_role.sfn_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.queue001_workflow.aws_iam_role.cloudwatch_sfn_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.ado_deregister_agents_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| aws_secretsmanager_secret.adopat | [aws_secretsmanager_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) |
| module.queue001_workflow.aws_ecr_repository.adoagent | [aws_ecr_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) |
| module.queue001_workflow.aws_kms_key.agent_data | [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) |
| module.queue001_workflow.aws_cloudwatch_log_group.scaling_workflow | [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)  |
| module.ado_queue_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.scaling_decider_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.queue001_workflow.aws_cloudwatch_event_rule.ado_scaling_workflow | [aws_cloudwatch_event_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) |
| module.queue001_workflow.aws_iam_role.agent_task_role | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.queue001_workflow.aws_iam_role_policy.workflow_execution_policy | [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| module.queue001_workflow.aws_ecs_cluster.ado_agent_pool | [aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) |
| module.scaling_decider_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| module.common_dependencies.aws_lambda_layer_version.lambda_dependencies | [aws_lambda_layer_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) |
| module.ado_deregister_agents_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| module.ado_queue_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| module.queue001_workflow.aws_iam_role_policy.agent_task_execution_policy | [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| module.queue001_workflow.aws_ecs_task_definition.ado_agent_task | [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| aws_security_group.ado_agent | [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| aws_iam_policy.ado_queue_metrics | [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| module.queue001_workflow.aws_sfn_state_machine.scaling_queue | [aws_sfn_state_machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) |
| aws_iam_role_policy_attachment.ado_deregister_agents_function | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| aws_iam_role_policy_attachment.scaling_decider_function | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| aws_iam_role_policy_attachment.ado_queue_metrics | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| module.queue001_workflow.aws_iam_role_policy.cloudwatch_sfn_execution | [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| module.queue001_workflow.aws_cloudwatch_event_target.sfn | [aws_cloudwatch_event_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) |
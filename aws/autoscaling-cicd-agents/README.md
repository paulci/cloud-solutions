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
- No automated trigger
- No state machine
- No Alarms
- No agent capacity monitoring

## Architecture
![Architecture Diagram](architecture01.png)


## State Machine
![Code and Visual Workflow Diagram](statemachine.png)


## Notes:
- Workflow is triggered if queue count is consistently above baseline or service count is consistently above baseline
- Supports multiple agent queues, configurable by json files in [config directory](src/ado_queue_function/config/)
- Max service count influenced by licenses held for self-hosted agents in Azure DevOps <insert links to dock>
- Agents are immutable and will terminate after each execution
- On scale-in, attempts are made to ensure no running jobs are terminated

## Future
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
| aws_iam_policy.ado_queue_metrics | [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| aws_iam_role_policy_attachment.ado_queue_metrics | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| aws_secretsmanager_secret.adopat | [aws_secretsmanager_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) |
| module.ado_queue_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.ado_queue_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| aws_iam_policy.agent_service_metrics | [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| aws_iam_role_policy_attachment.agent_service_metrics | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| module.service_metrics_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.service_metrics_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| module.queue_001_cluster.aws_cloudwatch_log_group.ado_agent_logs | [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)  |
| module.queue_001_cluster.aws_ecs_cluster.ado_agent_pool | [aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) |
| module.queue_001_cluster.aws_ecs_task_definition.ado_agent_task | [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| module.queue_001_cluster.aws_iam_role.agent_task_role |  [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| module.queue_001_cluster.aws_iam_role_policy.agent_task_execution_policy | [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| module.queue_001_cluster.aws_kms_key.agent_data | [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) |
| module.queue_001_cluster.aws_ssm_parameter.ado_pat | [aws_ssm_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) |
| aws_ecr_repository.adoagent | [aws_ecr_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) |
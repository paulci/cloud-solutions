# AWS Autoscaling Container Build Agent Solution for Azure DevOps Services

Configuration in this directory creates VPC and Security Group, with Autoscaling Azure DevOps agent(s) launched in Private Subnet.

## Requirements

| Name | Version |
|------|---------|
| aws cli | [aws](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) |
| pip3 | [>= 21.2.3](https://pip.pypa.io/en/stable/) |
| Terraform | [1.0.9](https://releases.hashicorp.com/terraform/1.0.9/) |
| provider/archive | [2.2.0](https://registry.terraform.io/providers/hashicorp/archive) |
| provider/aws | [3.6.3](https://registry.terraform.io/providers/hashicorp/aws) |

Azure DevOps PAT - Scope: Agent Pools (Read & manage)

## Modules

| Name | Source | Version |
|------|--------|---------|
| vpc | [aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/3.11.0) | 3.11.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| agent_cw_metric_prefix | Prefix for Cloudwatch Metric | string | Queue | N |
| assign_public_ip | Assign Public IP to Container | string | DISABLED | N |
| image_name | Name assigned to previously built docker image | string | adoagent | N |
| agent_cluster_name | Name to assign to the ECS Cluster | string | n/a | Y |
| agent_cw_namespace | Name to assign as the Cloudwatch Namespace for Azure DevOps Queue Metrics | string | n/a | Y |
| ado_org_name | Azure DevOps Service Org Name | string | n/a | Y |
| ado_pool_id | ID of Azure DevOps Agent Pool | int | n/a | Y |
| ado_pool_name | Name of Azure DevOps Agent Pool | string | n/a | Y |
| ado_pat | Personal Access Token scoped for Pool Management | string | n/a | Y |
| agent_security_group | AWS Security group ID for group with outbound access enabled (used by agent containers to communicate with Azure DevOps) | string | n/a | Y |
| subnet | AWS Private Subnet ID for containers to launch into | string | n/a | Y |

## Outputs
None


## Usage

To run this example you need to populate the missing values in `main.tf`

Example
```
module "agent_001" {
  agent_security_group = aws_security_group.ado_agent.id
  source               = "../../"
  ado_org_name         = "myorg"
  ado_pat              = "mypat" # With appropriate scope
  ado_pool_name        = "Dev-Team1-Pool"
  ado_pool_id          = "12"
  agent_cw_namespace   = "ADOAgentQueue"
  subnet               = module.vpc.private_subnets[0]
  agent_cluster_name   = "queue0012_cluster"
  image_name           = "devteam1_agent"
}
```
and execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Once created you will need to push your Agent Image - Base image included

```bash
$ aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
$ cd docker/
$ docker build -t adoagent .
$ docker tag adoagent:latest <account>.dkr.ecr.<region>.amazonaws.com/devteam1_agent:latest
$ docker push <account>.dkr.ecr.<region>.amazonaws.com/devteam1_agent:latest
```

Note that this example will create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Current Example Resources

| Name | Type | Instances |
|------|------|------|
| aws_security_group.ado_agent | [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | Single |
| module.vpc.aws_eip.nat[0] | [aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | Single |
| module.vpc.aws_internet_gateway.this[0] | [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | Single |
| module.vpc.aws_nat_gateway.this[0] | [aws_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | Single |
| module.vpc.aws_route.private_nat_gateway[0] | [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | Single |
| module.vpc.aws_route.public_internet_gateway[0] | [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | Single |
| module.vpc.aws_route_table.private[0] | [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | Single |
| module.vpc.aws_route_table.public[0] | [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | Single |
| module.vpc.aws_route_table_association.private[0] | [aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | Single |
| module.vpc.aws_route_table_association.public[0] | [aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | Single |
| module.vpc.aws_subnet.private[0] | [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | Single |
| module.vpc.aws_subnet.public[0] | [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | Single |
| module.vpc.aws_vpc.this[0] | [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | Single |
| module.agent_001.aws_iam_policy.ado_queue_metrics | [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | x instance of module |
| module.agent_001.aws_iam_role_policy_attachment.ado_deregister_agents_function | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | x instance of module |
| module.agent_001.aws_iam_role_policy_attachment.ado_queue_metrics | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | x instance of module |
| module.agent_001.aws_iam_role_policy_attachment.scaling_decider_function | [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | x instance of module |
| module.agent_001.aws_secretsmanager_secret.adopat | [aws_secretsmanager_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | x instance of module |
| module.agent_001.aws_secretsmanager_secret_version.base64pat | [aws_secretsmanager_secret_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | x instance of module |
| module.agent_001.module.ado_deregister_agents_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | x instance of module |
| module.agent_001.module.ado_deregister_agents_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | x instance of module |
| module.agent_001.module.ado_queue_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | x instance of module |
| module.agent_001.module.ado_queue_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | x instance of module |
| module.agent_001.module.common_dependencies.aws_lambda_layer_version.lambda_dependencies | [aws_lambda_layer_version](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version) | x instance of module |
| module.agent_001.module.common_dependencies.null_resource.install_python_dependencies | [null_resource](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | x instance of module |
| module.agent_001.module.scaling_decider_function.aws_iam_role.lambda_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | x instance of module |
| module.agent_001.module.scaling_decider_function.aws_lambda_function.function | [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_cloudwatch_event_rule.ado_scaling_workflow | [aws_cloudwatch_event_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_cloudwatch_event_target.sfn |  [aws_cloudwatch_event_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_cloudwatch_log_group.ado_agent_logs | [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_cloudwatch_log_group.scaling_workflow |  [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_ecr_repository.adoagent | [aws_ecr_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository)| x instance of module |
| module.agent_001.module.scaling_workflow.aws_ecs_cluster.ado_agent_pool | [aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_ecs_task_definition.ado_agent_task |  [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_iam_role.agent_task_role | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_iam_role.cloudwatch_sfn_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_iam_role.sfn_execution | [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_iam_role_policy.agent_task_execution_policy | [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_iam_role_policy.cloudwatch_sfn_execution | [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_iam_role_policy.workflow_execution_policy | [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_kms_key.agent_data | [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_sfn_state_machine.scaling_queue | [aws_sfn_state_machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) | x instance of module |
| module.agent_001.module.scaling_workflow.aws_ssm_parameter.ado_pat | [aws_ssm_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | x instance of module |

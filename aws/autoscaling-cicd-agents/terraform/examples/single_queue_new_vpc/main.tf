# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

#####################################################################
# New VPC with Private Subnets + Nat Gateway, using AWS Official    #
# VPC Module                                                        #
#####################################################################
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
# ADO Agent Resources                                               #
#####################################################################
module "agent_001" {
  agent_security_group = aws_security_group.ado_agent.id
  source               = "../../"
  ado_org_name         = ""
  ado_pat              = ""
  ado_pool_name        = ""
  ado_pool_id          = ""
  agent_cw_namespace   = ""
  subnet               = module.vpc.private_subnets[0]
  agent_cluster_name   = ""
  image_name           = ""
}

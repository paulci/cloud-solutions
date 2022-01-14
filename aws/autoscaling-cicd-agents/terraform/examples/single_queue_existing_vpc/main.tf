# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

resource "aws_security_group" "ado_agent" {
  name        = "ado_agent_security_group"
  description = "Allow access to poll ADO Orchestration Layer"
  vpc_id      = "vpc-"

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
  subnet               = "subnet-"
  agent_cluster_name   = ""
  image_name           = ""
}

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

variable "ado_org_name" {
  type = string
}

variable "ado_pat" {
  type      = string
  sensitive = true
}

variable "ado_pool_id" {
  type = string
}

variable "ado_pool_name" {
  type = string
}

variable "agent_cw_namespace" {
  type = string
}

variable "agent_cw_metric_prefix" {
  type    = string
  default = "Queue"
}

variable "assign_public_ip" {
  type    = string
  default = "DISABLED"
}

variable "subnet" {
  type = string
}

variable "agent_security_group" {
  type = string
}

variable "agent_cluster_name" {
  type = string
}

variable "image_name" {
  type    = string
  default = "adoagent"
}

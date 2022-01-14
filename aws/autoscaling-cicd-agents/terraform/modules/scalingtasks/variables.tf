# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

variable "ado_deregister_function_arn" {
  type = string
}

variable "ado_org_name" {
  type = string
}

variable "ado_pat_secret" {
  type      = string
  sensitive = true
}

variable "ado_pool_name" {
  type    = string
  default = ""
}

variable "ado_queue_function_arn" {
  type = string
}

variable "ado_queue_function_name" {
  type = string
}

variable "agent_cluster_name" {
  type = string
}

variable "agent_image" {
  type = string
}

variable "assign_public_ip" {
  type    = string
  default = "DISABLED"
}

variable "decider_function" {
  type = string
}

variable "image_name" {
  type    = string
  default = "adoagent"
}

variable "image_scan_on_push" {
  type    = bool
  default = true
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "security_group" {
  type = string
}

variable "state_machine_name" {
  type = string
}

variable "subnet" {
  type = string
}

variable "task_family" {
  type = string
}

variable "workflow_logging_enabled" {
  type    = bool
  default = false
}

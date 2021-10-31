# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

variable "agent_cluster_name" {
  type = string
}

variable "agent_image" {
  type = string
}

variable "ado_org_name" {
  type = string
}

variable "ado_pat_secret" {
  type      = string
  sensitive = true
}

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

variable "environment_variables" {
  type = map(any)
}

variable "function_name" {
  type = string
}

variable "function_source_dir" {
  type = string
}

variable "function_timeout_seconds" {
  type    = number
  default = 60
}

variable "handler" {
  type = string
}

variable "package" {
  type = string
}

variable "package_excludes" {
  type    = list(any)
  default = []
}

variable "runtime" {
  type = string
}

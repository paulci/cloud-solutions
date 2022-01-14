# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

variable "layer_name" {
  type = string
}

variable "dependency_source_dir" {
  type = string
}

variable "runtimes" {
  type = list(string)
}

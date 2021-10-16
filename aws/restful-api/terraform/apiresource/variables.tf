# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

variable "rest_api_id" {
    type = string
}

variable "parent_id" {
    type = string
}

variable "resource_path" {
    type = string
}

variable "http_method" {
    type = string
}

variable "authorization" {
    type = string
}

variable "authorizer_id" {
    type = string
}

variable "uri" {
    type = string
}

variable "function_name" {
    type = string
}

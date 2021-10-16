# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

output "v1_invoke_url" {
  value = "${aws_api_gateway_stage.v1.invoke_url}${module.helloresource.resource_path}"
}

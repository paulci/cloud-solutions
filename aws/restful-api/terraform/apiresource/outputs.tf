# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

output "resource_path" {
  value = aws_api_gateway_resource.modularresource.path
}


output "resource_id" {
  value = aws_api_gateway_resource.modularresource.id
}

output "method_id" {
  value = aws_api_gateway_method.modularresourcemethod.id
}

output "integration_id" {
  value = aws_api_gateway_integration.lambdaintegration.id
}

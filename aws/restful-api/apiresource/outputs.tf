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

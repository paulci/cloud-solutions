output "v1_invoke_url" {
  value = "${aws_api_gateway_stage.v1.invoke_url}${aws_api_gateway_resource.modularresource.path}"
}

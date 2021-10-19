output "v1_invoke_url" {
  value = "${aws_api_gateway_stage.v1.invoke_url}${module.helloresource.resource_path}"
}

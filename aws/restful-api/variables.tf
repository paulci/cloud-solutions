variable "api_name" {
  type = string
}

variable "jwtsecret" {
  type      = string
  sensitive = true
}

variable "resource_path" {
  type = string
}

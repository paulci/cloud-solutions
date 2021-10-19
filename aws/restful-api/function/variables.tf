variable "environment_variables" {
    type = map
    default = {}
}

variable "function_name" {
    type = string
}

variable "function_source_dir" {
    type = string
}
variable "handler" {
    type = string
}

variable "package" {
    type = string
}

variable "package_excludes" {
    type = list
    default = []
}

variable "runtime" {
    type = string
}

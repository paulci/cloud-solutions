# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

resource "aws_lambda_layer_version" "lambda_dependencies" {
  # Changes to requirements.txt requires re-provisioning
  filename            = "${path.module}/dependencies.zip"
  layer_name          = var.layer_name
  source_code_hash    = data.archive_file.package.output_base64sha256
  compatible_runtimes = var.runtimes
}

resource "null_resource" "install_python_dependencies" {
  triggers = {
    requirements = "${sha1(file("${path.module}/dependencies/requirements.txt"))}"
  }
  provisioner "local-exec" {
    command = "pip3 install -r  ${path.module}/dependencies/requirements.txt -t ${path.module}/dependencies/python --ignore-installed"
  }
}

data "archive_file" "package" {
  type        = "zip"
  source_dir  = "${path.module}/dependencies"
  output_path = "${path.module}/dependencies.zip"
  depends_on = [
    null_resource.install_python_dependencies,
  ]
}

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

resource "aws_lambda_layer_version" "lambda_dependencies" {
  filename            = "${var.dependency_source_dir}.zip"
  layer_name          = var.layer_name
  source_code_hash    = data.archive_file.package.output_base64sha256
  compatible_runtimes = var.runtimes
}

data "archive_file" "package" {
  type        = "zip"
  source_dir  = var.dependency_source_dir
  output_path = "${var.dependency_source_dir}.zip"
}

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

output "function_name" {
  value = aws_lambda_function.function.function_name
}

output "function_arn" {
  value = aws_lambda_function.function.arn
}

output "function_invoke_arn" {
  value = aws_lambda_function.function.invoke_arn
}

output "execution_role_name" {
  value = aws_iam_role.lambda_execution.name
}

output "login_url" {
  value = "https://${aws_cognito_user_pool_domain.default.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.web_client.id}&response_type=code&scope=aws.cognito.signin.user.admin+email+openid+profile&redirect_uri=http://localhost:3000"
}
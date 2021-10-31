# output "login_url" {
#   value = "https://${aws_cognito_user_pool.pool.domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.client.id}&response_type=code&scope=aws.cognito.signin.user.admin+email+openid+profile&redirect_uri=http://localhost:3000"
# }

#https://magnition-ci.auth.eu-west-1.amazoncognito.com/login?client_id=7c2fu8tqta5m5m6a5rp6fhlksc&response_type=code&scope=aws.cognito.signin.user.admin+email+openid+profile&redirect_uri=http://localhost:3000
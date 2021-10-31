data "aws_region" "current" {}

resource "aws_cognito_user_pool" "user_pool" {
  name                     = var.user_pool_name
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}
resource "aws_cognito_user_pool_domain" "default" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  domain       = var.domain_name
}
resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.user_pool.id
  provider_name = "Google"
  provider_type = "Google"
  
  provider_details = {
    client_id        = "XXXXXXXXXXXX.apps.googleusercontent.com"
    client_secret    = "XXXXXXXXXXXXXXXXX"
    authorize_scopes = "profile email openid"
    attributes_url_add_attributes = true
    attributes_url                = "https://people.googleapis.com/v1/people/me?personFields="
    authorize_url                 = "https://accounts.google.com/o/oauth2/v2/auth"
    oidc_issuer                   = "https://accounts.google.com"
    token_url                     = "https://www.googleapis.com/oauth2/v4/token"
    token_request_method          = "POST"
  }

  attribute_mapping = {
    email       = "email"
    family_name = "family_name"
    given_name  = "given_name"
    name        = "name"
    picture     = "picture"
    username    = "sub"
  }
}
resource "aws_cognito_user_pool_client" "web_client" {
  name                          = var.web_client_name
  user_pool_id                  = aws_cognito_user_pool.user_pool.id
  supported_identity_providers  = [aws_cognito_identity_provider.google.provider_name]
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = [
    "aws.cognito.signin.user.admin",
    "email",
    "openid",
    "profile",
  ]
  callback_urls = ["http://localhost:3000"]
  logout_urls   = ["http://localhost:3000"]
}
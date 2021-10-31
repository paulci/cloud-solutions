data "aws_region" "current" {}

module "cognito" {
    source = "./cognito"

    environment_variables = {
        region         = data.aws_region.current.name
    }

    web_client_name = var.web_client_name
    domain_name = var.domain_name
    user_pool_name = var.user_pool_name

}

#terraform plan -var user_pool_name=magnition-ci -var domain_name=magnition-ci -var web_client_name=magnition-ci
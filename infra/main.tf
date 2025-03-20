terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.75.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


module "lambda_function_auth" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.13.0"

  function_name = "apigateway-authorizer"
  description   = "lambda for authenticate api gateway requests"
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  attach_policy_json = true
  policy_json   = file("./lambda_auth/policy.json")

  environment_variables = {
    GOOGLE_CLIENT_ID = var.google_client_id
  }

  create_package         = false
  local_existing_package = "./lambda_package.zip"
}

data "template_file" "openapi_definition" {
  template = "${file("./openapi_definition.yml")}"
  vars = {
    aws_region              = data.aws_region.current.name
    lambda_authorizer_arn = module.lambda_function_auth.lambda_function_arn
    account_id              = data.aws_caller_identity.current.account_id
    apigateway_name         = var.apigateway_name
    apigateway_description  = var.apigateway_description
  }
}

resource "aws_api_gateway_rest_api" "rest_apigateway" {
  name           = var.apigateway_name
  description    = var.apigateway_description
  api_key_source = "HEADER"
  body           = "${data.template_file.openapi_definition.rendered}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "apigateway_deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_apigateway.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest_apigateway.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "allow_lambdaauth_apigateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_function_auth.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_apigateway.execution_arn}/*"
  depends_on = [ aws_api_gateway_rest_api.rest_apigateway ]
}
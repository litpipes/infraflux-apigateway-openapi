################################################
# [LitPipes] ECR Variables
# This variables could be used when the repository use ECR as container repository
# If this repository use the ECR as container repository then these variables will be automatically completed
################################################

#variable "ecr_image_tag" {
#  type = string
#}

#variable "ecr_image_repository" {
#  type = string
#}

################################################
# Your Variables
# Declare your variables below
################################################

#variable "ecr_image_repository" {
#  type = string
#}

variable "google_client_id" {
    type = string
#    default = ""
}

variable "apigateway_name" {
    type = string
#   default = ""
}

variable "apigateway_description" {
    type = string
#    default = ""
}

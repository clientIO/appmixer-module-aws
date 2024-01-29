# Good practice is to use s3 bucket to save the state and dynamodb table as lock to restrict access to the state
# For example:
#
# terraform {
#   backend "s3" {
#     bucket = "appmixer-terraform-state"
#     key    = "appmixer/terraform.tfstate"
#     region = "eu-central-1"
#   }
# }


provider "aws" {
  region = "eu-central-1"
}

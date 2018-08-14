variable "name" {}

variable "heroku_email" {}
variable "heroku_api_key" {}
variable "heroku_enterprise_team" {}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
  default = "us-east-1"
}

variable "aws_to_heroku_common_region" {
  default = {
    "eu-west-1" = "eu"
    "us-east-1" = "us"
  }
}

variable "aws_to_heroku_private_region" {
  default = {
    "eu-west-1"      = "dublin"
    "eu-central-1"   = "frankfurt"
    "us-west-2"      = "oregon"
    "ap-southeast-2" = "sydney"
    "ap-northeast-1" = "tokyo"
    "us-east-1"      = "virginia"
  }
}

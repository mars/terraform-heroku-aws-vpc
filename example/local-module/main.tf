provider "aws" {
  version    = "~> 1.10"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

provider "local" {
  version = "~> 1.1"
}

module "heroku_aws_vpc" {
  source     = "../../"
  name       = "${var.name}"
  aws_region = "${var.aws_region}"

  providers = {
    aws   = "aws"
    local = "local"
  }
}

resource "local_file" "aws_vpc_env" {
  content = <<EOF
AWS_VPC_REGION=${module.heroku_aws_vpc.region}
AWS_VPC_ID=${module.heroku_aws_vpc.id}
AWS_VPC_CIDR=${module.heroku_aws_vpc.cidr}
AWS_VPC_PUBLIC_SUBNET_ID=${module.heroku_aws_vpc.public_subnet_id}
AWS_VPC_PUBLIC_SUBNET_CIDR=${module.heroku_aws_vpc.public_subnet_cidr}
AWS_VPC_PRIVATE_SUBNET_ID=${module.heroku_aws_vpc.private_subnet_id}
AWS_VPC_PRIVATE_SUBNET_CIDR=${module.heroku_aws_vpc.private_subnet_cidr}
AWS_VPC_PRIVATE_STATIC_OUTGOING_IP=${module.heroku_aws_vpc.private_static_outgoing_ip}
EOF

  filename = "${path.module}/.env"
}

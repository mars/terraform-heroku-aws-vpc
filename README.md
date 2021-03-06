AWS VPC ready for 🍐 Heroku Private Spaces
===========================================

[![Terraform module](https://img.shields.io/badge/dynamic/json.svg?label=Terraform%20module&url=https%3A%2F%2Fregistry.terraform.io%2Fv1%2Fmodules%2Fmars%2Faws-vpc%2Fheroku&query=%24.version&colorB=%235D54E1)](https://registry.terraform.io/modules/mars/aws-vpc/heroku)

A [Terraform](https://www.terraform.io/) module providing:

* [AWS VPC](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html) compatible with [Private Space Peering](https://devcenter.heroku.com/articles/private-space-peering)
* Public & private subnets ([Scenario 2](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html))
* [Trustable static IP](https://devcenter.heroku.com/articles/private-spaces#trusted-ip-ranges) for outgoing traffic from private subnet 
* Each subnet internally peered with AWS S3

Usage
-----

⏩ See also: [example config peering the VPC with a Private Space](https://github.com/mars/terraform-aws-vpc-peered).

### Example apply

```bash
cd example/local-module/
terraform init
terraform apply \
  -var name=unique-identity \
  -var aws_access_key=xxxxx \
  -var aws_secret_key=yyyyy \
  -var aws_region=us-west-2
```

#### Example outputs

`example/local-module/.env` file containing various values from the provisioned infrastructure:

```
AWS_VPC_REGION=xx-xxxx-x
AWS_VPC_ID=vpc-xxxxxxxx
AWS_VPC_CIDR=x.x.x.x/x
AWS_VPC_PUBLIC_SUBNET_ID=subnet-xxxxxxxx
AWS_VPC_PUBLIC_SUBNET_CIDR=x.x.x.x/x
AWS_VPC_PRIVATE_SUBNET_ID=subnet-xxxxxxxx
AWS_VPC_PRIVATE_SUBNET_CIDR=x.x.x.x/x
AWS_VPC_PRIVATE_STATIC_OUTGOING_IP=x.x.x.x
```

### As a module

Invoke this config from another config:

```terraform
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
  source  = "mars/aws-vpc/heroku"
  version = "~> 1.0"

  providers = {
    aws   = "aws"
    local = "local"
  }
}
```

#### Module outputs

See [outputs.tf](outputs.tf).

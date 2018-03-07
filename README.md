AWS VPC ready for 🍐 Heroku Private Spaces
===========================================

A [Terraform](https://www.terraform.io/) configuration providing:

* [AWS VPC](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Introduction.html) compatible with [Private Space Peering](https://devcenter.heroku.com/articles/private-space-peering)
* Public & private subnets ([Scenario 2](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html))
* [Trustable static IP](https://devcenter.heroku.com/articles/private-spaces#trusted-ip-ranges) for outgoing traffic from private subnet 
* Each subnet internally peered with AWS S3

Usage
-----

```bash
terraform init

terraform apply \
  -var name=unique-identity \
  -var aws_access_key=xxxxx \
  -var aws_secret_key=yyyyy \
  -var aws_region=us-west-2
```

### Outputs

`.env` file containing various values from the provisioned infrastructure:

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

provider "aws" {
  version    = "~> 1.10"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

provider "heroku" {
  version = "~> 1.2"
  email   = "${var.heroku_email}"
  api_key = "${var.heroku_api_key}"
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

resource "heroku_space" "default" {
  name         = "${var.name}"
  organization = "${var.heroku_enterprise_team}"
  region       = "${lookup(var.aws_to_heroku_private_region, var.aws_region)}"
}

resource "heroku_space_inbound_ruleset" "default" {
  space = "${heroku_space.default.name}"

  rule {
    action = "allow"
    source = "0.0.0.0/0"
  }

  rule {
    action = "deny"
    source = "${module.heroku_aws_vpc.private_static_outgoing_ip}/32"
  }
}

data "heroku_space_peering_info" "default" {
  name = "${heroku_space.default.name}"
}

resource "aws_vpc_peering_connection" "request" {
  peer_owner_id = "${data.heroku_space_peering_info.default.aws_account_id}"
  peer_vpc_id   = "${data.heroku_space_peering_info.default.vpc_id}"
  vpc_id        = "${module.heroku_aws_vpc.id}"
}

resource "heroku_space_peering_connection_accepter" "accept" {
  space                     = "${heroku_space.default.name}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.request.id}"
}

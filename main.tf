provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

provider "heroku" {
  email   = "${var.heroku_email}"
  api_key = "${var.heroku_api_key}"
}

resource "aws_iam_user" "heroku_emr_manager" {
  name = "heroku_emr_manager_${var.name}"
}

resource "aws_iam_access_key" "heroku_emr_manager" {
  user = "${aws_iam_user.heroku_emr_manager.name}"
}

resource "aws_iam_user_policy_attachment" "heroku_emr_manager" {
  user       = "${aws_iam_user.heroku_emr_manager.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticMapReduceFullAccess"
}

resource "aws_vpc" "default" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.name}-ig"
  }
}

resource "aws_vpc_endpoint" "private_s3" {
  vpc_id       = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.2.0.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name}-public"
  }

  depends_on = ["aws_internet_gateway.default"]
}

resource "aws_eip" "nat" {
  vpc = true

  tags {
    Name = "${var.name}-nat"
  }
}

resource "aws_nat_gateway" "default" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.id}"
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.2.1.0/24"

  tags {
    Name = "${var.name}-private"
  }

  depends_on = ["aws_internet_gateway.default"]
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.default.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "${var.name}-public-routes"
  }
}

resource "aws_vpc_endpoint_route_table_association" "default_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.private_s3.id}"
  route_table_id  = "${aws_default_route_table.default.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.default.id}"
  }

  tags {
    Name = "${var.name}-private-routes"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.private_s3.id}"
  route_table_id  = "${aws_route_table.private.id}"
}

resource "aws_s3_bucket" "default" {
  bucket = "heroku-emr-${var.name}"
  acl    = "private"
}

resource "heroku_space" "default" {
  name         = "${var.name}-space"
  organization = "${var.heroku_enterprise_team}"
  region       = "${lookup(var.aws_to_heroku_private_region, var.aws_region)}"

  trusted_ip_ranges = [
    "0.0.0.0/0",
    "${aws_eip.nat.public_ip}/32",
  ]
}

resource "heroku_app" "default" {
  name   = "${var.name}"
  space  = "${heroku_space.default.name}"
  region = "${lookup(var.aws_to_heroku_private_region, var.aws_region)}"

  organization {
    name = "${var.heroku_enterprise_team}"
  }

  config_vars {
    AWS_REGION             = "${var.aws_region}"
    AWS_ACCESS_KEY_ID      = "${aws_iam_access_key.heroku_emr_manager.id}"
    AWS_SECRET_ACCESS_KEY  = "${aws_iam_access_key.heroku_emr_manager.secret}"
    AWS_S3_BUCKET          = "${aws_s3_bucket.default.id}"
    EMR_INSTANCE_SUBNET_ID = "${aws_subnet.private.id}"
  }
}

resource "heroku_addon" "database" {
  app  = "${heroku_app.default.name}"
  plan = "heroku-postgresql:private-0"
}

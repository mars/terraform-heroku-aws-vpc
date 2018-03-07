provider "aws" {
  version    = "~> 1.10"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.aws_region}"
}

provider "local" {
  version = "~> 1.1"
}

resource "aws_vpc" "default" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "${var.name}-vpc"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.name}-ig"
  }
}

resource "aws_vpc_endpoint" "peered_s3" {
  vpc_id       = "${aws_vpc.default.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.2.0.0/24"

  tags {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }

  tags {
    Name = "${var.name}-public-routes"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_main_route_table_association" "public" {
  vpc_id         = "${aws_vpc.default.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.peered_s3.id}"
  route_table_id  = "${aws_route_table.public.id}"
}

resource "aws_eip" "nat" {
  vpc = true

  tags {
    Name = "${var.name}-nat"
  }

  depends_on = ["aws_internet_gateway.public"]
}

resource "aws_nat_gateway" "private_to_public" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.id}"

  depends_on = ["aws_internet_gateway.public"]
}

resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.2.1.0/24"

  tags {
    Name = "${var.name}-private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.private_to_public.id}"
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
  vpc_endpoint_id = "${aws_vpc_endpoint.peered_s3.id}"
  route_table_id  = "${aws_route_table.private.id}"
}

resource "local_file" "aws_vpc_env" {
  content = <<EOF
AWS_VPC_REGION=${var.aws_region}
AWS_VPC_ID=${aws_vpc.default.id}
AWS_VPC_CIDR=${aws_vpc.default.cidr_block}
AWS_VPC_PUBLIC_SUBNET_ID=${aws_subnet.public.id}
AWS_VPC_PUBLIC_SUBNET_CIDR=${aws_subnet.public.cidr_block}
AWS_VPC_PRIVATE_SUBNET_ID=${aws_subnet.private.id}
AWS_VPC_PRIVATE_SUBNET_CIDR=${aws_subnet.private.cidr_block}
AWS_VPC_PRIVATE_STATIC_OUTGOING_IP=${aws_eip.nat.public_ip}
EOF

  filename = "${path.module}/.env"
}
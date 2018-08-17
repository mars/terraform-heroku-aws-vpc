provider "aws" {}
provider "local" {}

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
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "10.2.0.0/24"

  tags {
    Name = "${var.name}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "${var.name}-public-routes"
  }
}

resource "aws_route" "internet_gateway" {
  route_table_id            = "${aws_route_table.public.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = "${aws_internet_gateway.public.id}"
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

  tags {
    Name = "${var.name}-private-routes"
  }
}

resource "aws_route" "nat_gateway" {
  route_table_id            = "${aws_route_table.private.id}"
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = "${aws_nat_gateway.private_to_public.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  vpc_endpoint_id = "${aws_vpc_endpoint.peered_s3.id}"
  route_table_id  = "${aws_route_table.private.id}"
}

output "region" {
  value = "${var.aws_region}"
}

output "id" {
  value = "${aws_vpc.default.id}"
}

output "cidr" {
  value = "${aws_vpc.default.cidr_block}"
}

output "public_subnet_id" {
  value = "${aws_subnet.public.id}"
}

output "public_subnet_cidr" {
  value = "${aws_subnet.public.cidr_block}"
}

output "private_subnet_id" {
  value = "${aws_subnet.private.id}"
}

output "private_subnet_cidr" {
  value = "${aws_subnet.private.cidr_block}"
}

output "private_static_outgoing_ip" {
  value = "${aws_eip.nat.public_ip}"
}

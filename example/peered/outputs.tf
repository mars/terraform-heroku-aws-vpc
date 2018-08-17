output "health_checker_public_dns_name" {
  value = "${aws_instance.health_checker.public_dns}"
}

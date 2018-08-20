resource "heroku_app" "health" {
  name  = "${var.name}-health"
  space = "${heroku_space.default.name}"

  organization = {
    name = "${var.heroku_enterprise_team}"
  }

  region           = "${lookup(var.aws_to_heroku_private_region, var.aws_region)}"
  internal_routing = true

  config_vars {
    HEALTH_CHECKER_PRIVATE_IP       = "${aws_instance.health_checker.private_ip}"
    HEALTH_CHECKER_PRIVATE_DNS_NAME = "${aws_instance.health_checker.private_dns}"
  }
}

resource "heroku_slug" "health" {
  app = "${heroku_app.health.id}"

  process_types = {
    web = "ruby server.rb"
  }

  file_path = "slug.tgz"
}

resource "heroku_app_release" "health" {
  app     = "${heroku_app.health.id}"
  slug_id = "${heroku_slug.health.id}"
}

resource "heroku_formation" "health" {
  app        = "${heroku_app.health.id}"
  type       = "web"
  quantity   = 1
  size       = "Private-S"
  depends_on = ["heroku_app_release.health"]
}

resource "aws_key_pair" "health_checker" {
  key_name   = "${var.name}-key"
  public_key = "${var.instance_public_key}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-node-10.5.0-0-linux-ubuntu-16.04-x86_64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"] # Bitnami
}

resource "aws_instance" "health_checker" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${module.heroku_aws_vpc.public_subnet_id}"
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.health_checker.key_name}"

  vpc_security_group_ids = [
    "${aws_security_group.allow_ssh.id}",
  ]

  tags {
    Name = "HealthChecker"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound ssh traffic"
  vpc_id      = "${module.heroku_aws_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  access_key = "${var.access_key}",
  secret_key = "${var.secret_key}",
  region = "sa-east-1"
}
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "ssh" {
  name   = "ssh"
  vpc_id = "${aws_default_vpc.default.id}"
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "access-log-analysis-service" {
  name   = "access-log-analysis-service"
  vpc_id = "${aws_default_vpc.default.id}"
  ingress {
    protocol    = "tcp"
    from_port   = 8090
    to_port     = 8090
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticsearch_domain" "default-es" {
  domain_name           = "default-es"
  elasticsearch_version = "6.5"
  cluster_config {
    instance_type = "t2.small.elasticsearch"
    instance_count = 1
  }
  tags = {
    Domain = "default-es"
  }
}

data "aws_ami" "access_log_analysis_service_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["access-log-analysis-service*"]
  }
  owners = ["self"]
}

data "template_file" "access-log-analysis-service-init-script" {
  vars {
    elasticsearch_endpoint = "${aws_elasticsearch_domain.default-es.endpoint}"
  }
  template = <<-EOT
    #!/bin/bash
    ACCESS_LOG_ANALYSIS_CMD="access-log-analysis-service 8090 $${elasticsearch_endpoint}"
    crontab -l | { cat; echo \"@reboot $${ACCESS_LOG_ANALYSIS_CMD}\"; } | crontab -
  EOT
}

resource "aws_instance" "access-log-analysis-service" {
  count = 1
  ami = "${data.aws_ami.access_log_analysis_service_ami.id}"
  instance_type = "t2.micro"
  key_name = "vollino_aws"
  associate_public_ip_address = true
  security_groups = ["ssh", "access-log-analysis-service"]
  tags {
    Name = "access-log-analysis-service"
  }
  user_data = "${data.template_file.access-log-analysis-service-init-script.rendered}"
}
variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  access_key = "${var.access_key}",
  secret_key = "${var.secret_key}",
  region = "sa-east-1"
}

data "aws_region" "currentRegion" {}
data "aws_caller_identity" "currentUser" {}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "ssh-sg" {
  name   = "ssh-sg"
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

resource "aws_security_group" "access-log-analysis-service-sg" {
  name   = "access-log-analysis-service-sg"
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
  ebs_options {
    ebs_enabled = true
    volume_size = 10
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

resource "aws_instance" "access-log-analysis-service" {
  count = 1
  ami = "${data.aws_ami.access_log_analysis_service_ami.id}"
  instance_type = "t2.micro"
  key_name = "vollino_aws"
  associate_public_ip_address = true
  security_groups = ["ssh-sg", "access-log-analysis-service-sg"]
  tags {
    Name = "access-log-analysis-service"
  }
  user_data = <<-EOF
#! /bin/bash
ACCESS_LOG_ANALYSIS_CMD="/home/ubuntu/access-log-analysis-service*/bin/access-log-analysis-service 8090 ${aws_elasticsearch_domain.default-es.endpoint}"
crontab -u ubuntu -l | { cat; echo "@reboot $ACCESS_LOG_ANALYSIS_CMD"; } | crontab -u ubuntu -
sh $ACCESS_LOG_ANALYSIS_CMD &
  EOF
}

resource "aws_elasticsearch_domain_policy" "elasticsearch-policy" {
  domain_name = "${aws_elasticsearch_domain.default-es.domain_name}"

  access_policies = <<POLICIES
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${data.aws_caller_identity.currentUser.account_id}"
        ]
      },
      "Action": [
        "es:*"
      ],
      "Resource": "arn:aws:es:${data.aws_region.currentRegion.name}:${data.aws_caller_identity.currentUser.account_id}:domain/${aws_elasticsearch_domain.default-es.domain_name}/*"
    }
  ]
}
POLICIES
}
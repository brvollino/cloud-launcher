variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  access_key = "${var.access_key}",
  secret_key = "${var.secret_key}",
  region = "sa-east-1"
}

data "aws_ami" "access_log_analysis_service_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["access-log-analysis-service-*"]
  }
  owners = ["self"]
}
resource "aws_instance" "access-log-analysis-service" {
  count = 1
  ami = "${data.aws_ami.access_log_analysis_service_ami.id}"
  instance_type = "t2.micro"
  key_name = "vollino_aws"
  associate_public_ip_address = true
  tags {
    Name = "access-log-analysis-service"
  }
}
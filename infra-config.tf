variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  access_key = "${var.access_key}",
  secret_key = "${var.secret_key}",
  region = "sa-east-1"
}
resource "aws_instance" "access-log-analysis-service" {
  count = 1
  ami = "ami-0cb572d80a7417822"
  instance_type = "t2.micro"
  key_name = "vollino_aws"
  associate_public_ip_address = true
  tags {
    Name = "access-log-analysis-service"
  }
}
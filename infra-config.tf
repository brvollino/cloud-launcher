variable "access_key" {}
variable "secret_key" {}

provider "aws" {
  access_key="access_key",
  secret_key="secret_key"
}
resource "aws_instance" "access-log-analysis-service" {
  count = 1
  ami = "ami-0cb572d80a7417822"
  instance_type = "t2.micro"
  availability_zone= "sa-east-1"
  tags {
    Name = "access-log-analysis-service"
  }
}
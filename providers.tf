provider "aws" {
  region = "us-east-1"
}
# resource "aws_vpc" "my_vpc" {
#   count            = "${terraform.workspace == "dev" ? 1 : 0}"
#   cidr_block       = "${var.vpc_cidr}"
#   instance_tenancy = "default"
#
#   tags = {
#     Name = "${local.vpc_name}"
#     Env  = "${terraform.workspace}"
#   }
# }
# output "my_cidr" {
#   value = "${aws_vpc.my_vpc.cidr_block}"
# }
#terraform {
#  backend "s3" {
#    bucket         = "javabucket123"
#    key            = "terraform.tfstate"
#    region         = "us-east-1"
#    dynamodb_table = "Java-home-table"
#  }
#}

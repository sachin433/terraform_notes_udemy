locals {
  az_names = "${data.aws_availability_zones.azs.names}"
}
resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.my_app.id}"
  count      = "${length(local.az_names)}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
  #to count total aws_availability_zone

  availability_zone = "${local.az_names[count.index]}"

  tags = {
    Name = "PublicSubnet-${count.index + 1}"
  }
}

//igw is meant to connect subnet to internet using outbound route tables routes
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.my_app.id}"

  tags = {
    Name = "JavaVPCigw"
  }
}

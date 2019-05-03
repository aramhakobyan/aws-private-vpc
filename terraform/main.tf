
terraform {

  #  required_version = ">= 0.11.2"

  #backend "s3" {
  #  bucket = "tf.mydomain.io"
  #  key    = "state/${var.cluster_id}/terraform.tfstate"
  #  region = "${var.region}"
  #}

}

provider "aws" {
  region = "${var.region}"

}

# Grab the list of availability zones
data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "VPC-${var.namespace}"
  }
}


resource "aws_subnet" "public" {
  count = "${var.az-count}"

  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
  map_public_ip_on_launch = true

  tags {
    Name = "Public-${var.namespace}-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count = "${var.az-count}"

  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${cidrsubnet(aws_vpc.vpc.cidr_block, 8, count.index + 5)}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"

  map_public_ip_on_launch = false

  tags {
    Name = "Private-${var.namespace}-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "Gateway-${var.namespace}"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public.0.id}"
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat.id}"
  }

  tags {
    Name = "Private-${var.namespace}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Public-${var.namespace}"
  }
}

resource "aws_route_table_association" "rtbl-assoc-public" {
  count = "${var.az-count}"

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "rtbl-assoc-private" {
  count = "${var.az-count}"

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}


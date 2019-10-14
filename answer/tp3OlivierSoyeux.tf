# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"

  access_key = "AKIA6N4RZV6SM3CMCOHP"
  secret_key = "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"
}

resource "aws_key_pair" "deployer" {
  key_name   = "olivier-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAlJ1F1MI9gGM1RY7orC1BDgFi31xfpvj5JWRqyQRuj/tuV+GBIIYMcrBQ8wz9jXKiEjYqTXS8DWFhnaItceEFeVHM0SLC89gXFeh4sy/k7Y0HyBCxGs+zylyLHZDVe6gf56CsZBLWwMalIO6Y/Dl7VaLan10uTLtiZn8TTVSPuzoh+gpsaEXZMJw84s50SUjPEbYV5As1HZhwSHsIyJfn8sb8P3qWt0NlBk2Ct9ACPP+g5XdqxDvHN3Uy+4bjOtcjTc1xb+blgw5DESg1N2rmoXVKowKfqkn17Y6EgHrVdwm0KhQoYirm9PNm/cuXq5eAghuwAc2jZgmKdvgsCmYGHw== rsa-key-20190930"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "Olivier-Soyeux-Web" {
  key_name   = "olivier-key"
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  provisioner "remote-exec" {
      inline = [
      "sudo apt install git",
      "sudo apt install default-jdk",
      "sudo apt install maven"]
    }
    connection {
      type ="ssh"
      host = "${self.public_ip}"
      user = "ubuntu"
      private_key = "${file("cloudPrivate")}"
    }
}

resource "aws_vpc" "lgu_vpc"{
  cidr_block="172.16.0.0/16"
  enable_dns_hostnames= true
  enable_dns_support = true

  tags = {
    Name = "lgu_vpc"
  }
}

resource "aws_subnet" "lgu_sn"{
  cidr_block = "${cidrsubnet(aws_vpc.lgu_vpc.cidr_block,3,1)}"
  vpc_id = "${aws_vpc.lgu_vpc.id}"
  availability_zone = "eu_west_1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lgu_sn"
  }
}

resource "aws_internet_gateway" "lgu_igw"{
  vpc_id = "${aws_vpc.lgu_vpc.id}"
}

resource "aws_route_table" "lgu_rt"{
  vpc_id = "${aws_vpc.lgu_vpc.id}"

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.lgu_igw.id}"
  }

  tags =  {
    Name = "lgu_rt"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.61"
    }
  }

  required_version = ">= 1.2.0"
}

resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_tf_key_pair" {
  key_name	= var.key_name
  public_key    = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}

resource "aws_instance" "terraform_project" {
  ami           = var.ami
  instance_type = var.instance_type
  count   	= var.counter
  key_name 	= aws_key_pair.ssh_tf_key_pair.key_name
  associate_public_ip_address = true
  security_groups = ["${aws_security_group.ingress-all-test.id}"]

  tags = {
    Name = "${var.instance_tag}-[count.index]"
  }

  subnet_id	= "${aws_subnet.subnet-uno.id}"

}

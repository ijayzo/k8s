resource "aws_vpc" "test-env" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "test-env"
  }
}

resource "aws_eip" "ip-test-env" {
  count    = var.counter
  instance = "${aws_instance.terraform_project[count.index].id}"
  domain      = "vpc"
}

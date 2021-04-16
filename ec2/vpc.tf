provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "development" {
  cidr_block = "10.0.0.0/16" #2

  tags = {
    Environment = "development"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.development.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Environment = "development"
    Access = "private"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.development.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Environment = "development"
    Access = "public"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.development.id

  tags = {
    Environment = "development"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.development.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Environment = "development"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.development.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Environment = "development"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

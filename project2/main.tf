# main.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC-B
resource "aws_vpc" "VPC_B" {
  cidr_block = var.vpc_b_cidr
  tags = {
    Name = var.vpc_b_name
  }
}

# Public Subnet
resource "aws_subnet" "Public_Subnet_B" {
  vpc_id            = aws_vpc.VPC_B.id
  cidr_block        = var.public_subnet_b_cidr
  availability_zone = var.availability_zone_1
  tags = {
    Name = "Public-Subnet-B"
  }
}

# Private Subnet
resource "aws_subnet" "Private_Subnet_B" {
  vpc_id            = aws_vpc.VPC_B.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = var.availability_zone_2
  tags = {
    Name = "Private-Subnet-B"
  }
}

# Internet Gateway for VPC-B
resource "aws_internet_gateway" "IGW_B" {
  vpc_id = aws_vpc.VPC_B.id
  tags = {
    Name = "Internet-Gateway-B"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "NAT_GW_B" {
  subnet_id = aws_subnet.Public_Subnet_B.id
  allocation_id = aws_eip.NAT_EIP.id

  tags = {
    Name = "NAT-Gateway-B"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "NAT_EIP" {
  domain = "vpc"
}

# Route Table for Public Subnet
resource "aws_route_table" "Public_Route_Table_B" {
  vpc_id = aws_vpc.VPC_B.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW_B.id
  }

  tags = {
    Name = "Public-Route-Table-B"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "Private_Route_Table_B" {
  vpc_id = aws_vpc.VPC_B.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GW_B.id
  }

  tags = {
    Name = "Private-Route-Table-B"
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "Public_Association_B" {
  subnet_id      = aws_subnet.Public_Subnet_B.id
  route_table_id = aws_route_table.Public_Route_Table_B.id
}

# Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "Private_Association_B" {
  subnet_id      = aws_subnet.Private_Subnet_B.id
  route_table_id = aws_route_table.Private_Route_Table_B.id
}


# Security Group
resource "aws_security_group" "SG_B" {
  name        = "SG-B"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.VPC_B.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Network ACL for VPC-B
resource "aws_network_acl" "NACL_B" {
  vpc_id = aws_vpc.VPC_B.id

  ingress {
    protocol  = "-1"
    rule_no   = 100
    action    = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port   = 0
  }

  egress {
    protocol  = "-1"
    rule_no   = 100
    action    = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port   = 0
  }
}

# Network ACL Associations
resource "aws_network_acl_association" "NACL_Assoc_Pub" {
  subnet_id      = aws_subnet.Public_Subnet_B.id
  network_acl_id = aws_network_acl.NACL_B.id
}

resource "aws_network_acl_association" "NACL_Assoc_Pri" {
  subnet_id      = aws_subnet.Private_Subnet_B.id
  network_acl_id = aws_network_acl.NACL_B.id
}

# EC2 instance in Public Subnet (Public Access)
resource "aws_instance" "Public_EC2_B" {
  ami                 = "ami-0f88e80871fd81e91"  
  instance_type       = "t2.micro"
  subnet_id           = aws_subnet.Public_Subnet_B.id
  vpc_security_group_ids = [aws_security_group.SG_B.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    echo "Welcome to VPC-B EC2 instance - $(hostname)" > /var/www/html/index.html
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF

  tags = {
    Name = "Public-EC2-B"
  }
}

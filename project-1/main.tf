terraform{
    required_providers {
      
      aws={
        source="hashicorp/aws"
        version = "~> 5.0"
      }
    }
}

provider "aws"{
    region="us-east-1"
}

resource "aws_vpc" "UST-A-VPC"{
    cidr_block = "192.168.0.0/24"
    tags={
        Name="UST-A-VPC"
    }
}

#IG
resource "aws_internet_gateway" "UST_IGW" {
  vpc_id= aws_vpc.UST-A-VPC.id
  tags={
    Name="UST-IGW-tag"
  }
}

#public subnet
resource "aws_subnet" "UST-A-PubSub"{
    vpc_id=aws_vpc.UST-A-VPC.id 
    cidr_block="192.168.0.0/25"
    availability_zone="us-east-1a"
    tags={
        Name="UST-A-PubSub-tag"
    }
}

resource "aws_subnet" "UST-A-PriSub" {
    vpc_id=aws_vpc.UST-A-VPC.id
    cidr_block = "192.168.0.128/25"
    availability_zone ="us-east-1b"
    tags = {
      Name="UST-A-PriSub-tag"
    }
  
}

resource "aws_route_table" "UST-A-PubSub-RT"{
    vpc_id=aws_vpc.UST-A-VPC.id
    route{
        cidr_block="0.0.0.0/0"
        gateway_id = aws_internet_gateway.UST_IGW.id
    }
    tags={
        Name="UST-A-PubSub-RT-tag"
    }
}


resource "aws_route_table" "UST-A-PriSub-RT" {
    vpc_id=aws_vpc.UST-A-VPC.id
    route{
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.UST-A-VPC-NATGW.id
    }
    tags={
        Name="UST-A-PriSub-RT-tag"
    }
  
}

#RT ASSOCIATION

resource "aws_route_table_association" "PubSub-RT-Assoc"{
    subnet_id=aws_subnet.UST-A-PubSub.id 
    route_table_id = aws_route_table.UST-A-PubSub-RT.id  

}


resource "aws_route_table_association" "PriSub-RT-Assoc"{
    subnet_id = aws_subnet.UST-A-PriSub.id 
    route_table_id = aws_route_table.UST-A-PriSub-RT.id
}

#elastic ip for nat gaterway
resource "aws_eip" "eip-NAT-GW"{
    domain="vpc"
}


#NAT GATEWAY  
resource "aws_nat_gateway" "UST-A-VPC-NATGW"{
    allocation_id=aws_eip.eip-NAT-GW.id
    subnet_id=aws_subnet.UST-A-PubSub.id
    tags={
        Name="UST-A-VPC-NATGW-tag"
    }
}


#security group 
resource "aws_security_group" "UST-A-SG"{
    name="UST-A-SG"
    description = "Allow ssh and hhtp"
    vpc_id=aws_vpc.UST-A-VPC.id
    ingress{
        from_port = 22
        to_port = 22
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
    }

    ingress{
        from_port = 80
        to_port = 80
        protocol="tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port = 0
        protocol="-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#NACL 
resource "aws_network_acl" "UST-A-VPC-NACL" {
    vpc_id=aws_vpc.UST-A-VPC.id 
  ingress{
    protocol = "-1"
    rule_no=100
    action="allow"
    cidr_block="0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  egress{
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
}

#NACL ASSOCIATION with pubsub
resource "aws_network_acl_association" "NACL-PubSub" {
    subnet_id =aws_subnet.UST-A-PubSub.id 
    network_acl_id = aws_network_acl.UST-A-VPC-NACL.id
  
}

#NACL ASSOCIATION WIRH PRISUB 
resource "aws_network_acl_association" "NACL-PriSub" {
    subnet_id = aws_subnet.UST-A-PriSub.id
  network_acl_id = aws_network_acl.UST-A-VPC-NACL.id
} 

#ec2 public 
resource "aws_instance" "UST-A-VPC-Public-EC2" {
  ami="ami-0f88e80871fd81e91"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.UST-A-PubSub.id
  vpc_security_group_ids = [aws_security_group.UST-A-SG.id]
  associate_public_ip_address = true 
   user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    echo "Welcome to UST EC2 instance - $(hostname)" > /var/www/html/index.html
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF
  tags={
    Name="UST-A-Public-EC2"
  }
}

#ec2 private instance
resource "aws_instance" "UST-A-VPC-Private-EC2" {
    ami="ami-0f88e80871fd81e91"
    instance_type = "t2.micro"
    subnet_id=aws_subnet.UST-A-PriSub.id 
    vpc_security_group_ids = [aws_security_group.UST-A-SG.id] 
     associate_public_ip_address = false
     user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    echo "Welcome to UST EC2 instance - $(hostname)" > /var/www/html/index.html
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF
  
    tags = {
      Name="UST-A-Private-EC2"
    }
}


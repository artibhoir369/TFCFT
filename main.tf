resource "aws_vpc" "vpc-prod-MF" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "vpc-prod-MF"
  }
}

resource "aws_internet_gateway" "MF-igw" {
    vpc_id = aws_vpc.vpc-prod-MF.id
    tags = {
        Name = "MF-igw"
    }
}

resource "aws_route_table" "Pub-RT" {
  vpc_id = aws_vpc.vpc-prod-MF.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MF-igw.id
  }
  tags = {
    Name = "Pub-RT"
  }
}

resource "aws_route_table" "Pvt-RT" {
  vpc_id = aws_vpc.vpc-prod-MF.id
  tags = {
    Name = "Pvt-RT"
  }
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.vpc-prod-MF.id
  route_table_id = aws_route_table.Pub-RT.id
}

resource "aws_subnet" "App-subnet-1a" {
  vpc_id     = aws_vpc.vpc-prod-MF.id 
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "App-subnet-1a"
  }
}

resource "aws_subnet" "App-subnet-1b" {
  vpc_id     = aws_vpc.vpc-prod-MF.id 
  cidr_block = "10.0.2.0/24"
  tags = {
    Name = "App-subnet-1b"
  }
}

resource "aws_subnet" "DB-subnet-1a" {
  vpc_id     = aws_vpc.vpc-prod-MF.id 
  cidr_block = "10.0.7.0/24"
  tags = {
    Name = "DB-subnet-1a"
  }
}

resource "aws_subnet" "DB-subnet-1b" {
  vpc_id     = aws_vpc.vpc-prod-MF.id
  cidr_block = "10.0.8.0/24"
  tags = {
    Name = "DB-subnet-1b"
  }
}

resource "aws_route_table_association" "pub-1a" {
  subnet_id      = aws_subnet.App-subnet-1a.id
  route_table_id = aws_route_table.Pub-RT.id
}

resource "aws_route_table_association" "pub-1b" {
  subnet_id      = aws_subnet.App-subnet-1b.id
  route_table_id = aws_route_table.Pub-RT.id
}

resource "aws_route_table_association" "pvt-1a" {
  subnet_id      = aws_subnet.DB-subnet-1a.id
  route_table_id = aws_route_table.Pvt-RT.id
}

resource "aws_route_table_association" "pvt-1b" {
  subnet_id      = aws_subnet.DB-subnet-1b.id
  route_table_id = aws_route_table.Pvt-RT.id
}

resource "aws_security_group" "Pub-sg" {
  vpc_id = aws_vpc.vpc-prod-MF.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Pub-sg"
  }
}

resource "aws_security_group" "Pvt-sg" {
  vpc_id = aws_vpc.vpc-prod-MF.id
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["10.0.0.0/16"]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["10.0.0.0/16"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Pvt-sg"
  }
}

resource "aws_instance" "webserver" {
  instance_type = "t2.micro"
  ami = "ami-006dcf34c09e50022"
  key_name = "linux-key"
  vpc_security_group_ids = [ aws_security_group.Pub-sg.id ]
  subnet_id = aws_subnet.App-subnet-1a.id
  associate_public_ip_address = true
  user_data = <<EOF
  #!/bin/bash
  yum install httpd -y
  cd /var/www/html
  wget https://www.free-css.com/assets/files/free-css-templates/download/page287/cycle.zip
  unzip cycle.zip
  rm -f cycle.zip
  mv html/* .
  rm -rf html
  service httpd start
  EOF
  tags = {
    "Name" = "webserver"
  }
}
resource "aws_vpc" "abril_vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "Abril-VPC"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.abril_vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "abril_subnet1"
  }

}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.abril_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "abril_subnet2"
  }

}

resource "aws_internet_gateway" "abril_igw" {
  vpc_id = aws_vpc.abril_vpc.id
  
  tags = {
    Name = "abril_igw"
  }
}

resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.abril_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.abril_igw.id
  }
  tags = {
    Name = "abril_routes"
  }

}



resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rtb.id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "abril_sg" {
  vpc_id = aws_vpc.abril_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "abril_sg_webserver"
  }
  
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.abril_vpc.id

  ingress {
    description = "Allow HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allow traffic from webserver to database"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.abril_sg.id]
  }

  egress {
    description = "permitir trafico de salida"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "abril_sg_dbserver"
  }


  
}

resource "aws_key_pair" "abril_key" {
  key_name = "abril-key"
  public_key = file("./abril-key.pub")
  
}

resource "aws_instance" "webserver" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  subnet_id = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.abril_sg.id]
  key_name = aws_key_pair.abril_key.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_size = var.ec2_volume_size
    volume_type = var.ec2_volume_type
  }

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y apache2
systemctl enable apache2
systemctl start apache2
EOF

  tags = {    Name = "WebServer-abril"
    role = "web"
  }
  
}

resource "aws_instance" "dbwebserver" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.ec2_instance_type
  subnet_id = aws_subnet.public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  associate_public_ip_address = false

  root_block_device {
    volume_size = var.ec2_volume_size
    volume_type = var.ec2_volume_type
  }

  user_data = <<-EOF
#!/bin/bash
apt-get update -y
apt-get install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb
EOF

  tags = {
    Name = "dbServer-abril"
    role = "db"
  }


}

output "public_ips" {
  value = [
    aws_instance.webserver.public_ip,
    aws_instance.dbwebserver.public_ip
  ]


}

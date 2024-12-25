provider "aws" {
  region = "us-east-1"

}

####To deploy any resource###
# resource "<provider>_<resource_type>" "name" {
#   config options......
#   key = "value"
#   key2 = "value2"
# }

# Create a VPC
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}


resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

#Subnet

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "prod-subnet"
  }
}

#Associate subnet to Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}


#Create a security Group 

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web traffic and all outbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id


  tags = {
    Name = "allow_web"
  }

}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_https" {
  description       = "HTTPS"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_http" {
  description       = "HTTP"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_ssh" {
  description       = "SSH"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_rdp" {
  description       = "RDP"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3389
  ip_protocol       = "tcp"
  to_port           = 3389

}

###If you want to access website externaly
###Also need to add the code in the script:
###
resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_website" {
  description       = "Allwo Website ports"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080

}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#Network interface 

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_eip" "one" {
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw, aws_instance.web-server-instance]
}

###Option 1 - to expose the website only on localhost
# data "template_file" "user_data" {
#   template = file("${path.module}/Script-files/install-configure-IIS.ps1")
# }

###Option 2 - expose it via Public IP on port 8080
data "template_file" "user_data" {
  template = file("${path.module}/Script-files/test.ps1")
}

resource "aws_instance" "web-server-instance" {
  ami               = "ami-09ec59ede75ed2db7"
  instance_type     = "t3.medium"
  availability_zone = "us-east-1a"
  key_name          = "terraform"
  get_password_data = true

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "web-server"
  }
}

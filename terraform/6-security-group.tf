
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
  depends_on        = [aws_eip.one]
}
resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_http" {
  description       = "HTTP"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  depends_on        = [aws_eip.one]
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_ssh" {
  description       = "SSH"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  depends_on        = [aws_eip.one]
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_rdp" {
  description       = "RDP"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3389
  ip_protocol       = "tcp"
  to_port           = 3389
  depends_on        = [aws_eip.one]

}

###If you want to access website externaly
###Also need to add the code in the script:
###provides acces to the web from http://<Instance_Pub_IP>:<Port>
resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_website" {
  description       = "Allow Website ports"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
  depends_on        = [aws_eip.one]
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

###If you want to access website externaly
###Also need to add the code in the script:
###provides acces to the web from http://<Instance_Pub_IP>:<Port>
resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_website" {
  description       = "Allow Website ports"
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
  depends_on        = [aws_eip.one]
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

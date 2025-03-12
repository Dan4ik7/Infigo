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

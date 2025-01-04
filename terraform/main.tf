provider "aws" {
  region = "us-west-1"
  access_key = "AKIA6GBMHPK6XLSAWOE4"
  secret_key = "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"
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
  availability_zone = "us-west-1a"

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
###provides acces to the web from http://<Instance_Pub_IP>:<Port>
resource "aws_vpc_security_group_ingress_rule" "allow_ipv4_website" {
  description       = "Allow Website ports"
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


data "template_file" "user_data" {
  template = templatefile("${path.module}/user-data/user-data.ps1", {
    bucket_name = aws_s3_bucket.s3bucket.id
  })
}

resource "random_string" "random" {
  length = 4
  special = false
  upper = false
}

resource "aws_s3_bucket" "s3bucket" {
  bucket = "bucket-${random_string.random.result}"

  tags = {
      terraform = "True"
  }
  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

}

resource "aws_s3_object" "windows_exporter" {
  bucket = aws_s3_bucket.s3bucket.id
  key    = "windows-exporter.ps1"
  source = "${path.module}/user-data/windows-exporter.ps1"
}

resource "aws_s3_object" "storage_health" {
  bucket = aws_s3_bucket.s3bucket.id
  key    = "storage_health.ps1"
  source = "${path.module}/user-data/storage_health.ps1"
}

resource "aws_s3_object" "hyperv_health" {
  bucket = aws_s3_bucket.s3bucket.id
  key    = "hyperv_health.ps1"
  source = "${path.module}/user-data/hyperv_health.ps1"
}

resource "aws_instance" "web-server-instance" {
  ami               = "ami-0cbcac25efaba5ebf"
  instance_type     = "t3.medium"
  availability_zone = "us-west-1a"
  key_name          = "windows"
  get_password_data = true

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = data.template_file.user_data.rendered

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  tags = {
    Name = "web-server"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "ec2-s3-access-policy"
  description = "Allow EC2 instances to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.s3bucket.arn,
          "${aws_s3_bucket.s3bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_access_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Upload the zip file to S3
resource "aws_s3_bucket" "user_data_bucket" {
  bucket = "user-data-bucket-11"

}

resource "aws_s3_object" "user_data_zip" {
  bucket = aws_s3_bucket.user_data_bucket.id
  key    = "user-data.zip"
  source = "${path.module}/user-data.zip"

}

# IAM Role for EC2 to access S3
resource "aws_iam_role" "ec2_role" {
  name = "ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "S3AccessPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.user_data_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# User data script for EC2 instance
data "template_file" "user_data" {
  template = <<EOT
<powershell>
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Start-Transcript -Path "C:\\temp\\userdata.log" -Append

# Download and extract the user-data.zip file from S3
$bucketName = "${aws_s3_bucket.user_data_bucket.id}"
$objectKey = "user-data.zip"
$downloadPath = "C:\\temp\\user-data.zip"
$extractPath = "C:\\temp\\user-data"

Write-Output "Downloading user-data.zip from S3..."
aws s3 cp "s3://$bucketName/$objectKey" $downloadPath

Write-Output "Extracting user-data.zip..."
Expand-Archive -Path $downloadPath -DestinationPath $extractPath

Write-Output "Executing Install-configure-IIS.ps1..."
PowerShell -ExecutionPolicy Bypass -File "$extractPath\\install-configure-IIS.ps1"
</powershell>
EOT
}

resource "aws_instance" "web-server-instance" {
  ami               = "ami-09ec59ede75ed2db7"
  instance_type     = "t3.medium"
  availability_zone = "us-west-1a"
  key_name          = "windows"
  get_password_data = true

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "web-server"
  }
}

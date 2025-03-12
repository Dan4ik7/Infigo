
data "template_file" "user_data" {
  template = templatefile("${path.module}/user-data/user-data.ps1", {
    bucket_name = aws_s3_bucket.s3bucket.id
  })
}

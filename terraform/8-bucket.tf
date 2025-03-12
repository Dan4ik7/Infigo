
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

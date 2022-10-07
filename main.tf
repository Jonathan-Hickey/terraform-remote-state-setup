locals {
  unique_id = "53e1128e-bfc8-45d4-9000-9eb83f424d36"
}
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.unique_id}-terraform-state-bucket"

  object_lock_enabled = true

  tags = {
    Name        = "terraform-state"
    Environment = "root"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    aws_dynamodb_table.terraform_state_lock
  ]
}

resource "aws_s3_bucket_acl" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket.terraform_state
  ]
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }

  depends_on = [
    aws_s3_bucket.terraform_state
  ]
}

resource "aws_s3_bucket_object_lock_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 5
    }
  }

  depends_on = [
    aws_s3_bucket.terraform_state
  ]
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

variable unique_id  {
  type = string
  description = "Provide a unique id that can be used when creating your terraform state bucket"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.unique_id}-terraform-state-bucket"

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

resource "aws_kms_key" "terraform_state_key" {
  description             = "This key is used to encrypt the terraform state bucket objects"
}


resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state_key.arn
      sse_algorithm     = "aws:kms"
    }
  }

  depends_on = [
    aws_s3_bucket.terraform_state,
    aws_kms_key.terraform_state_key
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

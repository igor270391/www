terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# --------- Create remote bucket for storing remoutly state tf 
# 1. Create bucket S3
#    enable version <aws_s3_bucket_versioning>
#    add server side encryption <aws_s3_bucket_server_side_encryption_configuration>
#    block all public IP to the S3 <aws_s3_bucket_public_access_block>
# 2. Create DynamoDB table to use for locking
# 3. Add terraform backend S3 
#

terraform {
  backend "s3" {
    bucket = "terraform-state"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "ue-east-2"

    dynamodb_table = "terraform-locking-state"
    encrypt = true
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "enable" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "publick_access" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name = "terraform-locking-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

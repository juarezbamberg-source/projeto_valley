# variables.tf
variable "name" {
  description = "Unique identifier for the bucket (will be prefixed with hvt-)"
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "owner" {
  description = "Owner email or team"
  type        = string
}

variable "cost_center" {
  description = "Cost center code"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}

variable "logging_target_bucket" {
  description = "Name of the target bucket for server access logs (optional)"
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Log prefix when logging is enabled"
  type        = string
  default     = ""
}

# main.tf
locals {
  bucket_name = "hvt-${var.name}"
  common_tags = {
    Owner       = var.owner
    CostCenter  = var.cost_center
    Environment = var.environment
  }
  all_tags = merge(local.common_tags, var.additional_tags)
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  tags   = local.all_tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "this" {
  count = length(var.logging_target_bucket) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this.id
  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

# outputs.tf
output "bucket_id" {
  description = "ID of the created bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the created bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Domain name of the created bucket"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the created bucket"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

# example/main.tf
module "example_bucket" {
  source = "../"

  name        = "example-data"
  environment = "dev"
  owner       = "team-platform@hvt.com"
  cost_center = "CC-1234"

  additional_tags = {
    Project = "ProjectX"
  }

  # Uncomment to enable logging
  # logging_target_bucket  = "central-logs-bucket"
  # logging_target_prefix  = "s3-example/"
}
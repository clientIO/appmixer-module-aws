module "s3_bucket" {
  source  = "cloudposse/s3-bucket/aws"
  version = "4.0.1"
  enabled = true

  context    = module.label.context
  attributes = ["minio"]

  s3_object_ownership = "BucketOwnerEnforced"
  user_enabled        = true
  logging             = var.s3_config.logging
  versioning_enabled  = var.s3_config.versioning_enabled
  allowed_bucket_actions = [
    "s3:PutObject",
    "s3:GetObject",
    "s3:ListBucketMultipartUploads",
    "s3:ListBucketVersions",
    "s3:ListBucket",
    "s3:ListMultipartUploadParts",
    "s3:DeleteObject"
  ]
}

# Grants cluster permission to use KMS key
# for disk encryption
resource "aws_kms_grant" "kms_disk_grant" {
  name              = "${var.name}-disk-grant"
  key_id            = var.encryption.cluster_kms_key
  grantee_principal = var.instance_profile_role_arn
  operations        = local.required_kms_operations
}

# Grants cluster permission to use KMS key for
# S3 encryption
resource "aws_kms_grant" "kms_s3_grant" {
  name              = "${var.name}-bucket-grant"
  key_id            = var.encryption.s3_kms_key
  grantee_principal = var.instance_profile_role_arn
  operations        = local.required_kms_operations
}

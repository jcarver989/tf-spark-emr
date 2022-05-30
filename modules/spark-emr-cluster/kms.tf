# KMS key for cluster disk encryption
resource "aws_kms_key" "cluster_key" {
  description = "CMK for encrypting the cluster's EBS volumes"
}


# Grants cluster permission to use KMS key
# for disk encryption <-- TODO: could be added directly to KMS key policy
resource "aws_kms_grant" "kms_disk_grant" {
  name              = "${var.name}-disk-grant"
  key_id            = aws_kms_key.cluster_key.arn
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


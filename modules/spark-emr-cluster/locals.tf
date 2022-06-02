locals {
  required_kms_operations = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "DescribeKey"]
  service_role            = "EMR_DefaultRole"
  tags = merge(var.tags, {
    "for-use-with-amazon-emr-managed-policies" = true
  })
}

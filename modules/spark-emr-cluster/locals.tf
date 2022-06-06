locals {
  required_kms_operations       = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "DescribeKey"]
  service_role                  = "EMR_DefaultRole"
  trusted_ecr_registries        = concat(["local", "centos"], var.trusted_ecr_registries)
  trusted_ecr_registries_string = join(",", local.trusted_ecr_registries)
  tags = merge(var.tags, {
    "for-use-with-amazon-emr-managed-policies" = true
  })
}

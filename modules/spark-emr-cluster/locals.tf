locals {
  required_kms_operations = ["Encrypt", "Decrypt", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKey", "DescribeKey"]
}
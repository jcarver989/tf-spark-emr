# EMR security configuration that enables both encryption at rest
# and in transit

# Note: S3 encryption could be enabled via:
# "S3EncryptionConfiguration" : {
#   "EncryptionMode" : "SSE-KMS"
#   "AwsKmsKey" : var.encryption.s3_kms_key
# },
#
# But this isn't necessary if the bucket is already configured for default encryption using an AWS CMK (which is what we assume here)
resource "aws_emr_security_configuration" "security_configuration" {
  name = "${var.name}-security-config"

  configuration = jsonencode({
    "EncryptionConfiguration" : {
      "EnableAtRestEncryption" : true
      "EnableInTransitEncryption" : true,

      "AtRestEncryptionConfiguration" : {
        "LocalDiskEncryptionConfiguration" : {
          "EncryptionKeyProviderType" : "AwsKms",
          "AwsKmsKey" : var.encryption.cluster_kms_key
        }
      },

      "InTransitEncryptionConfiguration" : {
        "TLSCertificateConfiguration" : {
          "CertificateProviderType" : "PEM",
          "S3Object" : var.encryption.s3_path_to_cert
        }
      }
    }
  })
}

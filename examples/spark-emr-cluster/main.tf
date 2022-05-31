# This file contains a fully-bootable example for the spark-emr-cluster module
# It is intended for demonstration purposes, not for directly deploying to production

# =======
# EMR Cluster (Setup for Spark Streaming)
# =======
module "toy_emr_cluster" {
  source      = "../../modules/spark-emr-cluster"
  name        = "test-cluster"
  keep_alive  = true # this keeps the cluster alive when it has no running steps (useful for Spark streaming)
  s3_log_path = "s3://${aws_s3_bucket.test_bucket.bucket}/logs"

  vpc_id                    = aws_vpc.vpc.id
  subnet_ids                = [aws_subnet.private.id]
  egress_security_group_ids = [aws_security_group.vpc_endpoints.id]

  instance_profile_id       = aws_iam_instance_profile.instance_profile.id
  instance_profile_role_arn = aws_iam_role.iam_emr_profile_role.arn
  instance_type             = "m6g.xlarge"
  core_worker_count         = 2

  bootstrap_action = [{
    name = "Install Docker"
    path = "s3://toy-emr-cluster-test/python/bootstrap.sh"
    args = []
  }]

  docker_registry_urls = [aws_ecr_repository.ecr_repo.repository_url]
  encryption = {
    s3_kms_key      = aws_kms_key.bucket_key.arn
    cluster_kms_key = aws_kms_key.cluster_key.arn

    # For intstructions on generating certs for EMR, see:
    # https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-encryption-enable.html#emr-encryption-certificates
    s3_path_to_cert = "s3://${aws_s3_bucket.test_bucket.bucket}/certs.zip"
  }

  depends_on = [
    aws_vpc_endpoint.s3
  ]

}

# =======
# S3 (A toy S3 bucket, encrypted with a KMS CMK)
# =======
resource "aws_s3_bucket" "test_bucket" {
  bucket = "toy-emr-cluster-test"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.test_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# =======
# ECR
# =======
resource "aws_ecr_repository" "ecr_repo" {
  name                 = "emr-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# =======
# VPC  (A VPC with a private subnet + S3 gateway endpoint + KMS & ECR interface endpoints)
# =======

locals {
  vpc_cidr            = "168.31.0.0/16"
  private_subnet_cidr = "168.31.0.0/20"
}

resource "aws_kms_key" "bucket_key" {
  description = "key for toy-emr-cluster-test bucket"
}

resource "aws_kms_key" "cluster_key" {
  description = "key for toy-emr-cluster-test bucket"
}



resource "aws_vpc" "vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    name                                       = "emr_test"
    "for-use-with-amazon-emr-managed-policies" = true
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = local.private_subnet_cidr

  tags = {
    name                                       = "emr_test"
    "for-use-with-amazon-emr-managed-policies" = true
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.r.id
}

# EMR has a validation check for VPC route tables
# that will fail if it thinks there are 0 egress rules
# Hence why we use a gateway endpoint here vs an interface
# (gateway endpoints require plopping an egress rule on the routing table)
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.vpc.id
  service_name    = "com.amazonaws.us-west-2.s3"
  route_table_ids = [aws_route_table.r.id]
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-west-2.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-west-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-west-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids = [
    aws_security_group.vpc_endpoints.id
  ]
}


resource "aws_security_group" "vpc_endpoints" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.private_subnet_cidr]
  }
}


# =======
# Instance Profile (A very permissive instance profile, meant for demonstration purposes)
# =======
resource "aws_iam_instance_profile" "instance_profile" {
  name = "toy-spark-cluster-instance-profile"
  role = aws_iam_role.iam_emr_profile_role.id
}

resource "aws_iam_role" "iam_emr_profile_role" {
  name = "iam_emr_profile_role"

  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_emr_profile_policy" {
  name = "iam_emr_profile_policy"
  role = aws_iam_role.iam_emr_profile_role.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Resource" : "*",
      "Action" : [
        "cloudwatch:*",
        "dynamodb:*",
        "ec2:Describe*",
        "elasticmapreduce:Describe*",
        "elasticmapreduce:ListBootstrapActions",
        "elasticmapreduce:ListClusters",
        "elasticmapreduce:ListInstanceGroups",
        "elasticmapreduce:ListInstances",
        "elasticmapreduce:ListSteps",
        "rds:Describe*",
        "s3:*",
        "sdb:*",
        "sns:*",
        "sqs:*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:ListTagsForResource",
        "ecr:DescribeImageScanFindings"
      ]
    }]
  })
}

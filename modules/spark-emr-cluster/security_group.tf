# Grab the S3 prefix list (for our gateway endpoint)
data "aws_region" "current" {}
data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}


# This group is managed by EMR, EMR populates the ingress/egress rules 
resource "aws_security_group" "cluster_security_group" {
  name        = "${var.name}-cluster-security-group"
  description = "EMR managed security group for Spark instances"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow incoming traffic from other instances in the cluster."
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  egress {
    description = "Allow outgoing traffic to other instances in the cluster."
    from_port   = 0
    to_port     = 0
    protocol    = -1
    self        = true
  }

  egress {
    description     = "Allow outgoing HTTPs traffic to specified security groups (e.g. VPC interface endpoints)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.egress_security_group_ids
  }

  egress {
    description     = "Allow outgoing HTTPs traffic to VPC gateway endpoint for S3"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.s3.id]
  }

  # EMR will append its own rules to this security group (as it's "EMR managed").
  # So this is necessary to prevent Terraform from clobbering those rules on the next deploy.
  lifecycle {
    ignore_changes = [
      ingress,
      egress,
    ]
  }

  tags = var.tags
}

# EMR clusters running in a private subnet (like this cluster), need an additional "service access security group".
# See: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-man-sec-groups.html#emr-sg-elasticmapreduce-sa-private
resource "aws_security_group" "service_access_security_group" {
  name        = "${var.name}-service-security-group"
  description = "Allows service communication"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow incoming traffic from instances in the cluster"
    from_port       = 9443
    to_port         = 9443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_security_group.id]
  }

  egress {
    description     = "Allow outgoing traffic to instances in the cluster"
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster_security_group.id]
  }

  tags = var.tags
}
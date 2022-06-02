# Grab the S3 prefix list (for our gateway endpoint)
data "aws_region" "current" {}
data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}


# This group is managed by EMR, EMR populates the ingress/egress rules
resource "aws_security_group" "cluster_security_group" {
  name_prefix = "${var.name}-cluster-security-group"
  description = "EMR managed security group for Spark instances"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "intra_cluster_ingress" {
  security_group_id = aws_security_group.cluster_security_group.id
  description       = "Allow incoming traffic from other instances in the cluster."
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}

resource "aws_security_group_rule" "intra_cluster_egress" {
  security_group_id = aws_security_group.cluster_security_group.id
  description       = "Allow outgoing traffic to other instances in the cluster."
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  self              = true
}


resource "aws_security_group_rule" "s3_vpc_endpoint_egress" {
  security_group_id = aws_security_group.cluster_security_group.id
  description       = "Allow outgoing HTTPs traffic to VPC gateway endpoint for S3"
  type              = "egress"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.s3.id]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

resource "aws_security_group_rule" "blessed_security_group_egress" {
  for_each                 = toset(var.egress_security_group_ids)
  security_group_id        = aws_security_group.cluster_security_group.id
  description              = "Allow outgoing HTTPs traffic to specified security groups (e.g. VPC interface endpoints)"
  type                     = "egress"
  source_security_group_id = each.key
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
}


# EMR clusters running in a private subnet (like this cluster), need an additional "service access security group".
# See: https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-man-sec-groups.html#emr-sg-elasticmapreduce-sa-private
resource "aws_security_group" "service_access_security_group" {
  name        = "${var.name}-service-security-group"
  description = "Allows service communication"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "service_access_security_group_ingress" {
  security_group_id        = aws_security_group.service_access_security_group.id
  description              = "Allow incoming traffic from instances in the cluster"
  type                     = "ingress"
  source_security_group_id = aws_security_group.cluster_security_group.id
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "service_access_security_group_egress" {
  security_group_id        = aws_security_group.service_access_security_group.id
  description              = "Allow outgoing traffic to instances in the cluster"
  type                     = "egress"
  source_security_group_id = aws_security_group.cluster_security_group.id
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
}

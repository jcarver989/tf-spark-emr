# Creates an EMR cluster configured for Apache Spark
resource "aws_emr_cluster" "cluster" {
  name                              = var.name
  release_label                     = var.emr_version
  applications                      = ["Spark"]
  keep_job_flow_alive_when_no_steps = var.keep_alive
  step_concurrency_level            = var.step_concurrency_level
  log_uri                           = var.s3_log_path
  security_configuration            = aws_emr_security_configuration.security_configuration.id
  service_role                      = local.service_role

  ec2_attributes {
    subnet_ids                        = var.subnet_ids
    emr_managed_master_security_group = aws_security_group.cluster_security_group.id
    emr_managed_slave_security_group  = aws_security_group.cluster_security_group.id
    service_access_security_group     = aws_security_group.service_access_security_group.id
    instance_profile                  = var.instance_profile_id
  }

  master_instance_group {
    instance_type = var.instance_type
  }

  core_instance_group {
    instance_type  = var.instance_type
    instance_count = var.core_worker_count
  }

  tags = local.tags

  depends_on = [
    aws_kms_grant.kms_disk_grant,
    aws_kms_grant.kms_s3_grant
  ]
}

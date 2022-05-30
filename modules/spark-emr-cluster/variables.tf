variable "name" {
  type        = string
  description = "name of the EMR cluster"
}

variable "emr_version" {
  type        = string
  default     = "emr-6.6.0"
  description = "EMR release version to run. See: https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-release-components.html"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID the cluster runs in"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs this cluster runs in"
}

variable "egress_security_group_ids" {
  type        = list(string)
  description = "List of security groups this cluster is allowed to send outgoing HTTPs traffic to (e.g. VPC interface endpoints for other AWS services)"
}

variable "instance_type" {
  type        = string
  default     = "m6g.xlarge" # cheap-ish graviton $0.039/hour in west-2
  description = "Instance type the driver + worker nodes use"
}

variable "instance_profile_id" {
  type = string
  description = "Instance profile for the cluster"
}

variable "instance_profile_role_arn" {
  type = string
  description = "Instance profile role arn for the cluster"
}

variable "core_worker_count" {
  type        = number
  description = "Number of core worker nodes in the cluster"
}

variable "tags" {
  type = map(string)
  default = {
    "for-use-with-amazon-emr-managed-policies" = true
  }
}

variable "service_role" {
  type        = string
  default     = "EMR_DefaultRole"
  description = "EMR service role for the cluster"
}

variable "keep_alive" {
  type        = bool
  default     = false
  description = "Keeps the cluster alive even if there are no currently running steps. Set this to true for streaming clusters."
}

variable "step_concurrency_level" {
  type        = number
  default     = 2
  description = "Number of EMR steps that can run concurrently on this cluster"
}

variable "encryption" {
  type = object({
    s3_kms_key      = string
    s3_path_to_cert = string
  })
  description = "Required configuration to enable encryption at rest and in transit on the cluster"
}

variable "s3_log_path" {
  type        = string
  description = "S3 location for EMR logs, should start with s3://..."
}

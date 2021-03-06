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
  type        = string
  description = "Instance profile for the cluster"
}

variable "instance_profile_role_arn" {
  type        = string
  description = "Instance profile role arn for the cluster"
}

variable "core_worker_count" {
  type        = number
  description = "Number of core worker nodes in the cluster"
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
    cluster_kms_key = string
  })
  description = "Required configuration to enable encryption at rest and in transit on the cluster"
}

variable "s3_log_path" {
  type        = string
  description = "S3 location for EMR logs, should start with s3://..."
}


variable "bootstrap_actions" {
  type = list(object({
    name = string
    path = string
    args = list(string)
  }))

  description = "Boostrap action that runs before any job steps. s3:// paths to scripts are supported. And if you're running Docker make sure to configure a bootstrap action that installs Docker on the master node, per: https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-spark-docker.html"
  default     = []
}


variable "trusted_ecr_registries" {
  type        = list(string)
  description = "List of trusted ECR registries, which may be used by the cluster to pull images for Docker-ized jobs. These should look like: <account>.dkr.ecr.<region>.amazonaws.com, and end in .com, .com/<repo-name>"
  default     = []
  validation {
    condition = alltrue([
      for e in var.trusted_ecr_registries : can(regex("amazonaws\\.com$", e))
    ])
    error_message = "ECR registry endpoints must end in .com, did you include the repo name by accident, e.g. .com/<repo-name>?"
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

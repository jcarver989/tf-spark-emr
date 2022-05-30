# Module: spark-emr-cluster
Provisions an EMR cluster that runs Apache Spark.

## Features
 - Makes running a Spark EMR cluster easier 
 - Preconfigured security groups that don't allow for cross-cluster communication
 - Encryption in transit (TLS) and at rest come "out of the box" (EBS volumes are encrypted with a dedicated cluster CMK)

## Usage
```hcl
module "example_cluster" {
  source     = "../../modules/spark-emr-cluster"
  name       = "example-cluster"
  keep_alive = true # useful for Spark streaming
  s3_log_path = "s3://foo-bucket/logs"

  vpc_id                    = aws_vpc.vpc.id
  subnet_ids                = [aws_subnet.private.id]
  egress_security_group_ids = [aws_security_group.vpc_endpoints.id]

  instance_profile_id  = aws_iam_instance_profile.instance_profile.id
  instance_profile_role_arn  = aws_iam_role.iam_emr_profile_role.arn
  instance_type     = "m6g.xlarge"
  core_worker_count = 2

  encryption = {
    s3_kms_key      = aws_kms_key.bucket_key.arn

    # For intstructions on generating certs for EMR, see:
    # https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-encryption-enable.html#emr-encryption-certificates
    s3_path_to_cert = "s3://foo-bucket/certs.zip"
}
```

## Configuration
See [variables.tf](./variables.tf) for a full list of configuration options.

## Gotchas
 - If you don't pass a custom service role, the default EMR service role will be used, which requires tagging both your VPC + private subnet with `for-use-with-amazon-emr-managed-policies = true`

 - EMR complains if it detects that your VPC's route table has zero routes to external resources. Thus, if running your cluster in an isolated subnet, you'll likely need an S3 gateway endpoint to make EMR happy (gateway endpoints add a route to the VPC table that appeases that validation check). 

 ## Future work (in no particular order):
 - (Nicer) batch support (allow caller to specify a step to run on cluster boot + terminate when finished)
 - Autoscaling support
 - Spot instance support (for task instances, which are safe to use with spot as "task" instances don't persist data)
 - More/better options for configuring monitoring and/or logging
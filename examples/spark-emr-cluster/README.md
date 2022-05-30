# Example: spark-emr-cluster

This directory contains a fully-bootable Terraform project that uses the [spark-emr-cluster module](../../modules/spark-emr-cluster/). At a high-level this example provisions (non-comprehensive): 

- A VPC with a private subnet
- VPC endpoints for: S3 (gateway) and KMS (interface)
- A S3 bucket + KMS Key
- An EMR cluster running Apache Spark in the private subnet

See [main.tf](./main.tf) for implementation details.

## Deploying Infrastructure
```hcl
terraform init
terraform apply
```

## Deploying Code
The EMR cluster is assumed to be a Spark Streaming cluster, and thus is configured to stay alive even when it has no jobs running. See [scripts/deploy.sh](./scripts/deploy.sh) for an example of how to submit jobs (EMR steps) to the cluster.
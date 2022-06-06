#!/usr/bin/env bash


# This script provides an example for how to submit a Spark job that uses a Docker image.

export AWS_REGION="us-west-2"
CLUSTER=$1

echo "Deploying..."

aws emr add-steps \
--cluster-id $CLUSTER \
--steps file://./steps.json \
--region us-west-2


echo "Done."
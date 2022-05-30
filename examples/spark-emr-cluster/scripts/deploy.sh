#!/usr/bin/env bash

# This is an example script (not prod ready) for how to (re)deploy 
# a Spark Streaming job on EMR. Something similar could be used for automated deployments in a CI/CD pipeline 

# This script:
# 1. Kills all running steps on the cluster
# 2. Starts a new Spark Streaming step on the cluster (presumably with the "new" code we want to deploy)

# Since Spark Streaming clusters will be writing Delta Lake tables, and
# Delta Lake does not support multi-cluster concurrent writes to S3 (due to an S3 limitation)
# Deployments require "downtime" in the sense that we have to kill any streaming queries
# currently running on the cluster, before we deploy the new code 

# TODOs: 
# 1. Wait for existing queries to completely stop before deploying (avoids race conditions)
# 2. Cleanups

export AWS_REGION="us-west-2"

CLUSTER="j-2G8EI6V6CJ2A8"
JAR="s3://toy-emr-cluster-test/artifacts/scala-spark-playground-assembly-0.1.0-SNAPSHOT.jar"
MAIN_CLASS="org.example.spark.App"

RUNNING_STEPS=$(aws emr list-steps --cluster-id $CLUSTER --region us-west-2 --step-states PENDING RUNNING \
| jq ".Steps | .[] | .Id" | xargs -I '{}' echo "{}")

if [ -z $RUNNING_STEPS ]
then
 echo "The cluster has no running steps."
else
  echo "The cluster is running the following steps: $RUNNING_STEPS. Cancelling those before deploying..."
  aws emr cancel-steps --cluster-id $CLUSTER  --step-ids $RUNNING_STEPS
fi

echo "Deploying..."
aws emr add-steps \
--cluster-id $CLUSTER \
--steps Type=Spark,Name="Spark Streaming",ActionOnFailure=CONTINUE,Args=[--class,$MAIN_CLASS,$JAR] \

echo "Done."
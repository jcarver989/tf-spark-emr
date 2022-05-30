#!/usr/bin/env bash

# This is an example script (not prod ready) that (re)deploys 
# Spark Streaming queries running on EMR. Something similar could be used for automated deployments in a CI/CD pipeline 

# This script assumes the Spark cluster is writing to a Delta Lake table, which at the time of writing does not support
# multi-cluster concurrent writes to S3 (without an external data store). 

# Blue/green deployments aren't an option here (as that'd result in concurrent multi-cluster writes to S3). So instead we: 
# 1. Keep the original cluster running
# 2. Request to terminate all jobs running on the cluster
# 3. Start the new job (with the updated code we're deploying)

# TODOs: 
# - Wait for existing queries to completely stop before deploying (avoids race conditions)

export AWS_REGION="us-west-2"

CLUSTER=$1
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
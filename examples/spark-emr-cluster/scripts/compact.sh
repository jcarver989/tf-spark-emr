#!/usr/bin/env bash

# This is an example script (not prod ready) that demonstrates how we can (re)deploy 
# a Spark Streaming cluster running on EMR in our CI system. 

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
MAIN_CLASS="org.example.spark.Compactor"

echo "Deploying..."
aws emr add-steps \
--cluster-id $CLUSTER \
--steps Type=Spark,Name="Delta Compactor",ActionOnFailure=CONTINUE,Args=[--class,$MAIN_CLASS,$JAR,"s3://toy-emr-cluster-test/delta-lake"] \

echo "Done."
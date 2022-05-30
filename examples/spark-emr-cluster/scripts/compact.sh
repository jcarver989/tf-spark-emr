#!/usr/bin/env bash

# This is an example script (not prod ready) that demonstrates how
# a periodic "compaction" job could be run ontop of a Spark Streaming cluster. 

# Streaming clusters often produce many small files in S3, so it's useful to
# compact those files periodically (e.g. hourly, daily etc). And something similar
# to this script could easily be run on a scheduled cadence.

# Assuming we're compacting a Delta Lake table:
# 1. This job could be as simple as just calling OPTIMIZE s3://... (see: https://docs.delta.io/latest/optimizations-oss.html#optimize-performance-with-file-management) running the compaction job concurrently
# 2. Running the "compaction" job concurrently with other jobs on the cluster that might be writing to the same table is totally fine. 
# Delta Lake supports concurrent writes to S3 so long write requests originate from the same cluster.

export AWS_REGION="us-west-2"

CLUSTER=$1
JAR="s3://toy-emr-cluster-test/artifacts/scala-spark-playground-assembly-0.1.0-SNAPSHOT.jar"
MAIN_CLASS="org.example.spark.Compactor"

echo "Deploying..."
aws emr add-steps \
--cluster-id $CLUSTER \
--steps Type=Spark,Name="Delta Compactor",ActionOnFailure=CONTINUE,Args=[--class,$MAIN_CLASS,$JAR,"s3://toy-emr-cluster-test/delta-lake"] \

echo "Done."
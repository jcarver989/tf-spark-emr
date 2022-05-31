#!/usr/bin/env bash
export AWS_REGION="us-west-2"

CLUSTER=$1
ENTRYPOINT="s3://toy-emr-cluster-test/python/main.py"
DOCKER_IMAGE="575767027669.dkr.ecr.us-west-2.amazonaws.com/emr-ecr-repo:pyspark"

echo "Deploying..."

STEPS=$(cat <<-EOF 
  {
    "Type": "CUSTOM_JAR",
    "Name": "PySpark",
    "ActionOnFailure": "CONTINUE",
    "Jar": "command-runner.jar",
    "Args": [
      "spark-submit",
      "--deploy-mode cluster",
      "--conf spark.executorEnv.YARN_CONTAINER_RUNTIME_TYPE=docker",
      "--conf spark.executorEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$DOCKER_IMAGE",
      "--conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_TYPE=docker",
      "--conf spark.yarn.appMasterEnv.YARN_CONTAINER_RUNTIME_DOCKER_IMAGE=$DOCKER_IMAGE",
      "$ENTRYPOINT"
    ]
  }
EOF
)


aws emr add-steps \
--cluster-id $CLUSTER \
--steps file://./steps.json \
--region us-west-2


echo "Done."
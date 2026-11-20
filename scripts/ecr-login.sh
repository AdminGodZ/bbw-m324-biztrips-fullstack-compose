#!/usr/bin/env bash
# Logs Docker in to Amazon ECR with the current Learner Lab credentials and prints ECR_REGISTRY.
set -euo pipefail
region="${AWS_REGION:-us-east-1}"
account=$(aws sts get-caller-identity --query Account --output text) \
  || { echo "No valid AWS credentials - start the Learner Lab and export the AWS CLI values first." >&2; exit 1; }
registry="$account.dkr.ecr.$region.amazonaws.com"
aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$registry"
echo "export ECR_REGISTRY=$registry"

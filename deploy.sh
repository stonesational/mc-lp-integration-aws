#!/bin/sh

ECR_REPO_NAME=mc-lp-connector-ecr
AWS_REGION=us-west-1

echo;echo "Getting the ECR Repository URI for $ECR_REPO_NAME on $AWS_REGION"
ECR_REPOSITORY=$(aws ecr describe-repositories \
  --query "repositories[?repositoryName=='$ECR_REPO_NAME'].repositoryUri" --output=text)

echo;echo "Found ECR Repository: $ECR_REPOSITORY"

echo;echo "Retrieving an authentication token and authenticating your Docker client to ECR Registry."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY

echo;echo "Building Docker image with Tag $ECR_REPO_NAME"
docker build -t "$ECR_REPO_NAME" .

echo;echo "Tagging Docker image so you can push the image to the repository"
docker tag $ECR_REPO_NAME:latest $ECR_REPOSITORY:latest

echo;echo "Pushing Docker image to your AWS repository"
docker push $ECR_REPOSITORY:latest

echo;echo "Restarting Fargate Service"
aws ecs update-service \
    --cluster mc-lp-connector-cluster \
    --service mc-lp-connector-ecs-service \
    --force-new-deployment
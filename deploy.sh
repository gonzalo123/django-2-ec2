#!/usr/bin/env bash

set -a
[ -f deploy.env ] && . deploy.env
set +a

echo "$(tput setaf 1)Building docker images ...$(tput sgr0)"
docker build -t ec2-web -t ec2-web:latest -t $ECR/ec2-web:latest .
docker build -t ec2-nginx -t $ECR/ec2-nginx:latest .docker/nginx

echo "$(tput setaf 1)Pusing to ECR ...$(tput sgr0)"
aws ecr get-login-password --region $REGION --profile $PROFILE |
  docker login --username AWS --password-stdin $ECR
docker push $ECR/ec2-web:latest
docker push $ECR/ec2-nginx:latest

CMD="docker stack deploy -c $DOCKER_COMPOSE_YML ec2 --with-registry-auth"
echo "$(tput setaf 1)Deploying to EC2 ($CMD)...$(tput sgr0)"
echo "$CMD"

DOCKER_HOST="ssh://$HOST" $CMD
echo "$(tput setaf 1)Building finished $(date +'%Y%m%d.%H%M%S')$(tput sgr0)"

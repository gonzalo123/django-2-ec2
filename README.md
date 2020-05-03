### Deploying Django application to AWS EC2 instance with Docker

In AWS we have several ways to deploy Django (and not Django applicaions) with Docker. We can use ECS or EKS clusters. If we don't have one ECS or Kubernetes cluster up and running, maybe it can be complicated. Today I want to show how deploy one Django application in production mode within a EC2 host. Let's start.

I'm getting older to provision one host by hand I prefer to use docker. The idea is create one EC2 instance (one simple Amazon Linux AMI AWS-supported image). This host don't have docker installed. We need to install it. When we launch one instance, when we're configuring the instance, we can specify user data to configure an instance or run a configuration script during launch.
 
We only need to put this shell script to set up docker

```shell script
#! /bin/bash
yum update -y
yum install -y docker
usermod -a -G docker ec2-user
curl -L https://github.com/docker/compose/releases/download/1.25.5/docker-compose-`uname -s`-`uname -m` | sudo tee /usr/local/bin/docker-compose > /dev/null
chmod +x /usr/local/bin/docker-compose
service docker start
chkconfig docker on

rm /etc/localtime
ln -s /usr/share/zoneinfo/Europe/Madrid /etc/localtime

ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

docker swarm init
```

We also need to attach one IAM role to our instance. This IAM role only need to allow us the following policies:
* AmazonEC2ContainerRegistryReadOnly (because we're going to use AWS ECR as container registry)
* CloudWatchAgentServerPolicy (because we're going to emit our logs to Cloudwatch)

Also we need to set up a security group to allow incoming SSH conections to port 22 and HTTP conections (in our example to port 8000)

When we launch our instance we need to provide a keypair to connect via ssh. I like to put this keypair in my .ssh/config

> .ssh/config
``` 
Host xxx.eu-central-1.compute.amazonaws.com
    User ec2-user
    Identityfile ~/.ssh/keypair-xxx.pem
```

To deploy our application we need to follow those steps:
* Build our docker images
* Push our images to a container registry (in this case ECR)
* Deploy the application.

I've created a simple shell script called deploy.sh to perform all tasks:
```shell script
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
```

This script assumes that there's a deploy.env file with our personal configuration (AWS profile, the host of the EC2, instance, The ECR and things like that)

```
PROFILE=xxxxxxx

DOKER_COMPOSE_YML=docker-compose.yml
HOST=ec2-user@xxxx.eu-central-1.compute.amazonaws.com

ECR=9999999999.dkr.ecr.eu-central-1.amazonaws.com
REGION=eu-central-1
```

In this example I'm using docker swarm to deploy the application. I want to play also with secrets. This dummy application don't have any sensitive information but I've created one "ec2.supersecret" variable

```shell script
echo "super secret text" | docker secret create ec2.supersecret -
```

That's the docker-compose.yml file:

```yaml
version: '3.8'
services:
  web:
    image: 999999999.dkr.ecr.eu-central-1.amazonaws.com/ec2-web:latest
    command: /bin/bash ./docker-entrypoint.sh
    environment:
      DEBUG: 'False'
    secrets:
      - ec2.supersecret
    deploy:
      replicas: 1
    logging:
      driver: awslogs
      options:
        awslogs-group: /projects/ec2
        awslogs-region: eu-central-1
        awslogs-stream: app
    volumes:
      - static_volume:/src/staticfiles
  nginx:
    image: 99999999.dkr.ecr.eu-central-1.amazonaws.com/ec2-nginx:latest
    deploy:
      replicas: 1
    logging:
      driver: awslogs
      options:
        awslogs-group: /projects/ec2
        awslogs-region: eu-central-1
        awslogs-stream: nginx
    volumes:
      - static_volume:/src/staticfiles:ro
    ports:
      - 8000:80
    depends_on:
      - web
volumes:
  static_volume:

secrets:
  ec2.supersecret:
    external: true
```

And that's all. Maybe ECS or EKS are better solutions to deploy docker applications in AWS, but we also can deploy easily to one docker host in a EC2 instance that it can be ready within a couple of minutes.
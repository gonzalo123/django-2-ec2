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
#!/usr/bin/env bash

set -a
[ -f deploy.env ] && . deploy.env
set +a

echo "$(tput setaf 1)Creating Secrets ...$(tput sgr0)"
CMD="
  echo \"super secret text\" | docker secret create ec2.supersecret -
  echo \"super secret text2\" | docker secret create ec2.supersecret2 -
"
ssh $HOST -C "$CMD"

echo "$(tput setaf 1)secret initialization done $(date +'%Y%m%d.%H%M%S')$(tput sgr0)"

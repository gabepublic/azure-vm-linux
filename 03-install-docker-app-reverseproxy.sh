#!/bin/bash

RESOURCE_GROUP_NAME=gt-experiment
LOCATION=westus3
VM_NAME=vm-small-01
VM_IMAGE=Ubuntu2204
ADMIN_USERNAME=azureuser

sudo apt-get -y update
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
#cat /etc/group | grep docker
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker

# login github container registry
#export CR_PAT=<replace-with-YOUR_TOKEN>
#$ echo $CR_PAT | docker login ghcr.io -u <replace-with-USERNAME> --password-stdin
docker pull ghcr.io/gabepublic/llm-chainlit-jokes-amd64:main
docker logout
docker run -d --name llm-chainlit-jokes -p 8000:8000 ghcr.io/gabepublic/llm-chainlit-jokes-amd64:main
curl localhost:8000

sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.ssl
sudo cp -f ./03-default-nginx-reverseproxy.txt /etc/nginx/site-available/default

sudo nginx -s reload

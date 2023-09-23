#!/bin/bash

RESOURCE_GROUP_NAME=gt-experiment
LOCATION=westus3
VM_NAME=vm-small-01
VM_IMAGE=Ubuntu2204
ADMIN_USERNAME=azureuser

sudo apt-get -y update
sudo apt-get -y install nginx

sudo mkdir /etc/nginx/ssl
sudo chmod 700 /etc/nginx/ssl

secretsname=$(sudo find /var/lib/waagent/ -name "*.prv" | cut -c -57)
sudo cp $secretsname.crt /etc/nginx/ssl/gt-cert.cert
sudo chmod 644 /etc/nginx/ssl/gt-cert.cert
sudo cp $secretsname.prv /etc/nginx/ssl/gt-cert.prv
sudo chmod 600 /etc/nginx/ssl/gt-cert.prv

sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.orig
sudo cp -f ./02-default-nginx-ssl.txt /etc/nginx/site-available/default

sudo nginx -s reload

# open port 443
az vm open-port --port 443 --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME

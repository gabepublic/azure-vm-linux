#!/bin/bash

RESOURCE_GROUP_NAME=gt-experiment
LOCATION=westus3
VM_NAME=vm-small-01
VM_IMAGE=Ubuntu2204
ADMIN_USERNAME=azureuser

az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

az vm create \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --name $VM_NAME \
  --image $VM_IMAGE \
  --admin-username $ADMIN_USERNAME \
  --ssh-key-values ~/.ssh/id_rsa_azure.pub \
  --public-ip-sku Standard \
  --size Standard_B1s

IP_ADDRESS=$(az vm show --show-details --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME --query publicIps --output tsv)

# ssh port 22 is opened by default
# open port 80 if need to test, otherwise continue
#az vm open-port --port 80 --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME
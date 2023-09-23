# azure-vm-linux

Create azure linux vm


## Create a linux vm using **azure portal** and install nginx manually

- Source: [Quickstart: Create a Linux virtual machine in the Azure portal](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu)

- Follow the steps provided in the above "Source" document to create a vm

- In the "Project details", Resource group: `gt-basic-101`

- In the "Instance details" screen, 
  - Virtual machine name: vm-small-basic
  - select the smallest "Size" vm for this exercise

- Choose the closest "Availability zone" to you

- Select "SSH public key"

- For "Inbound port rules", select:
  - Public inbound ports: Allow selected ports
  - Select inbound ports: HTTP (80), SSH (22)

- Make sure download the private key file, `*.pem`, and save it safely.
  The `pem` file is the public ssh key that will be used to ssh into
  the vm. 

- Go to resource page; get the Public IP address

- Using SSH client to connect to the vm; use the ssh public key file

- After ssh into the vm, install nginx as follow:
```
sudo apt-get -y update
sudo apt-get -y install nginx
```

- Open browser to `http://<ip-address>/

- NEXT, explore:
  - [Create a Linux virtual machine with the Azure CLI](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli)
  - more advance [Create a complete Linux virtual machine with the Azure CLI](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/create-cli-complete)


## Install **azure cli** on linux host (Ubuntu)

- Source: [Install the Azure CLI on Linux](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)

- Install with one command & configure
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az init
```

## Create a linux vm using **azure cli**

- NOTE: azure CLOUD SHELL requires storage to persist files; and storage
  cost money. For cheaper method, see the instructions above, 
  "Install azure cli on linux apt (Ubuntu)", for using `az cli` on local
  host.  

- Sources: both sources below 
  - [Quickstart: Create a Linux virtual machine with the Azure CLI](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli)
  - [Tutorial: Use TLS/SSL certificates to secure a web server](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-secure-web-server))

- Defined Environment variables
```
export RESOURCE_GROUP_NAME=gt-experiment
export LOCATION=westus3
export VM_NAME=vm-small-02
export VM_IMAGE=Ubuntu2204
export ADMIN_USERNAME=azureuser
```
  - Remember to `unset` when no longer needed!!!

- Create the public-private key pair
  Source: [Quick steps: Create and use an SSH public-private key pair for Linux VMs in Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys)
```
ssh-keygen -m PEM -t rsa -b 4096
```
  Note: create your own instead of using `--generate-ssh-keys` is better
  for manageability from reuse. Otherwise, too many `pem` file to keep track.

- Create the resource_group and vm:
```
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

az vm create \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --name $VM_NAME \
  --image $VM_IMAGE \
  --admin-username $ADMIN_USERNAME \
  --ssh-key-values ~/.ssh/id_rsa_azure_thendean_outlook.pub \
  --public-ip-sku Standard \
  --size Standard_B1s
```

- Check IP address
```
export IP_ADDRESS=$(az vm show --show-details --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME --query publicIps --output tsv)
```

- Open ports
```
az vm open-port --port 22,80 --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME
```

- Open browser to `http://<ip-address>/

- Options: continue manual installations; see instructions below;
  - Option-1: manually install nginx and configure ssl
  - Option-2: following option-1, manually install docker engine,
    docker image, run docker container, configure nginx as reverse proxy  

- Delete the vm
```
az vm delete -g $RESOURCE_GROUP_NAME -n $VM_NAME --yes
az group delete -n $RESOURCE_GROUP_NAME --yes
```

### Option-1: Manual install nginx and **configure SSL**

- Install nginx
```
sudo apt-get -y update
sudo apt-get -y install nginx
```

- Create self-signed certificates;
  Source: [How to Set Up SSL with NGINX](https://www.youtube.com/watch?v=X3Pr5VATOyA)
```
sudo mkdir /etc/nginx/ssl
sudo chmod 700 /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/gt-cert.key \
  -out /etc/nginx/ssl/gt-cert.crt
```

  - ALTERNATIVELY, use the certificate that are pre-installed with the vm
```
secretsname=$(find /var/lib/waagent/ -name "*.prv" | cut -c -57)
sudo cp $secretsname.crt /etc/nginx/ssl/gt-cert.cert
sudo chmod 644 /etc/nginx/ssl/gt-cert.cert
sudo cp $secretsname.prv /etc/nginx/ssl/gt-cert.prv
sudo chmod 600 /etc/nginx/ssl/gt-cert.prv
```  

- Modify & configure ssl in `/etc/nginx/site-enabled/default`. 
```
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;	
    ssl_certificate /etc/nginx/ssl/gt-cert.crt;
    ssl_certificate_key /etc/nginx/ssl/gt-cert.prv;

    location / {
        root /var/www/html;
        index index.html index.htm index.nginx-debian.html;
    }
}
```

- Restart nginx
```
sudo nginx -t
sudo nginx -s reload
```

- Open port 443 from azure cli.
  Note: if the port 80 already opened, needs to delete manually from
  azure portal.
```
az vm open-port --port 443 --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME
```

- Open browser to `https://<ip-address>/


### Option-2: Manual install docker image & setup nginx reverse proxy

The reverse proxy route the https traffic to the container.

- References:
  - [How To Deploy a React Application with Nginx on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-react-application-with-nginx-on-ubuntu-20-04)
  - [NGINX as Reverse Proxy for Node or Angular application](https://www.digitalocean.com/community/tutorials/nginx-reverse-proxy-node-angular)

- Option-1 above needs to be completed before continuing.

- Next install docker
```
sudo apt-get -y update
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
cat /etc/group | grep docker
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

- To pull docker image from the private github container registry.
  Use the Authenticating with a personal access token (classic).
```
export CR_PAT=<replace-with-YOUR_TOKEN>
$ echo $CR_PAT | docker login ghcr.io -u <replace-with-USERNAME> --password-stdin
Password:<enter-password>
> Login Succeeded

WARNING! Your password will be stored unencrypted in /home/azureuser/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
$ docker pull ghcr.io/<username>/<image-name>
[...]
$ docker images
$ docker logout
$ docker run -d --name <replace-with-appname> -p 8000:8000  ghcr.io/<replace-with-username>/<replace-with-imagename>

$curl localhost:8000
```
Source: [Authenticating with a personal access token (classic)](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic)

- Configure nginx reverse proxy
```
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;

    server_name _;
    ssl_certificate /etc/nginx/ssl/gt-cert.crt;
    ssl_certificate_key /etc/nginx/ssl/gt-cert.prv;

    location / {
        proxy_pass http://localhost:8000;
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
}
```

- Restart nginx
```
sudo nginx -t
sudo nginx -s reload
```

- Open browser to `https://<ip-address>/

### Troubleshooting

- [Nginx: Troubleshooting WebSocket Connection Failed: A Concise Guide](https://apidog.com/blog/websocket-connection-failed/#:~:text='WebSocket%20connection%20failed'%20typically%20indicates,or%20higher%2C%20WebSocket%20is%20supported.)


## Create a linux vm using azure CLI and install SSL nginx (Not working!!)

NEED further troubleshooting!!!

- Source: [Tutorial: Use TLS/SSL certificates to secure a web server](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-secure-web-server)

- Defined Environment variables
```
export RESOURCE_GROUP_NAME=gt-experiment
export LOCATION=westus3
export VM_NAME=vm-small-03
export VM_IMAGE=Ubuntu2204
export ADMIN_USERNAME=azureuser
```
  - Remember to `unset` when no longer needed!!!

- Create the public-private key pair
  Source: [Quick steps: Create and use an SSH public-private key pair for Linux VMs in Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys)
```
ssh-keygen -m PEM -t rsa -b 4096
```
  Note: create your own instead of using `--generate-ssh-keys` is better
  for manageability from reuse. Otherwise, too many `pem` file to keep track.

- Create the resource_group and vm.
  NOTE:
  - issue with `az keyvault certificate create` due to empty string returns
    by `az keyvault certificate get-default-policy`; so create the Certificate
	from the azure portal.
```
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

export KEYVAULT_NAME=gt-azure-keyvault
export CERT_NAME=gt-cert-default-policy

az keyvault create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $KEYVAULT_NAME \
    --enabled-for-deployment

az keyvault certificate create \
    --vault-name $KEYVAULT_NAME \
    --name $CERT_NAME \
    --policy "$(az keyvault certificate get-default-policy)"

secret=$(az keyvault secret list-versions \
          --vault-name $KEYVAULT_NAME \
          --name $CERT_NAME \
          --query "[?attributes.enabled].id" --output tsv)
vm_secret=$(az vm secret format --secrets "$secret" -g $RESOURCE_GROUP_NAME --keyvault $KEYVAULT_NAME)

az vm create \
    --resource-group $RESOURCE_GROUP_NAME \
    --location $LOCATION \
    --name $VM_NAME \
    --image $VM_IMAGE \
    --admin-username $ADMIN_USERNAME \
    --ssh-key-values ~/.ssh/id_rsa_azure_thendean_outlook.pub \
    --public-ip-sku Standard \
    --size Standard_B1s \
    --custom-data cloud-init-web-server.txt
#    --secrets "$vm_secret"
```

- Check IP address
```
export IP_ADDRESS=$(az vm show --show-details --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME --query publicIps --output tsv)
```

- Open ports
```
az vm open-port --port 22,443 --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME
```

- Delete the vm
```
az vm delete -g $RESOURCE_GROUP_NAME -n $VM_NAME --yes
az group delete -n $RESOURCE_GROUP_NAME --yes
``` 

## Create linux vm using azure portal and install docker

Source:
- [Quickstart: Create a Linux virtual machine in the Azure portal](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu)

- Follow the steps in the "Source" to create a vm

- Make sure download the private key file, `*.pem`, and save it safely

- Go to resource page

- Using SSH client to connect to the vm

- After ssh into the vm, perform the following:
```
sudo apt-get -y update
```

- Next install docker
```
sudo apt-get install ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
cat /etc/group | grep docker
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
```

- Optional - test the docker installation
```
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
719385e32844: Pull complete 
Digest: sha256:4f53e2564790c8e7856ec08e384732aa38dc43c52f02952483e3f003afbf23db
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

$ docker rm hello-world
$ docker image rm hello-world
```

- To pull docker image from the private github container registry.
  Use the Authenticating with a personal access token (classic).
```
export CR_PAT=<replace-with-YOUR_TOKEN>
$ echo $CR_PAT | docker login ghcr.io -u <replace-with-USERNAME> --password-stdin
Password:<enter-password>
> Login Succeeded

WARNING! Your password will be stored unencrypted in /home/azureuser/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
$ docker pull ghcr.io/<username>/<image-name>
[...]
$ docker images
$ docker logout
```
Source: [Authenticating with a personal access token (classic)](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry#authenticating-with-a-personal-access-token-classic)



## Archived - Setup https, create certifcates using certbot

To set up HTTPS for a React application running on an Azure Virtual Machine, you'll need to obtain and configure an SSL/TLS certificate and then configure your web server (e.g., Nginx or Apache) to use HTTPS. Here are step-by-step instructions:
1. **Obtain an SSL/TLS Certificate:**
   You can obtain an SSL/TLS certificate from a certificate authority (CA) or use a free certificate from Let's Encrypt. For this example, we'll use Let's Encrypt with Certbot.
   a. SSH into your Azure VM:
      ```
      ssh <username>@<public-ip-address>
      ```
   b. Install Certbot (Let's Encrypt's official client):
      ```
      sudo apt update
      sudo apt install certbot python3-certbot-nginx
      ```
   c. Request a certificate for your domain (replace `<your-domain>` with your actual domain):
      ```
      sudo certbot --nginx -d <your-domain>
      ```
   d. Follow the Certbot prompts to configure your certificate.

2. **Configure Nginx with SSL:**
   Assuming you are using Nginx to serve your React application, you need to configure Nginx to use the SSL certificate:
   a. Open the Nginx configuration file for your site:
      ```
      sudo nano /etc/nginx/sites-available/default
      ```
   b. Inside the `server` block, make sure you have the following lines, replacing `<your-domain>` and the certificate paths accordingly:
      ```
      server {
          listen 443 ssl;
          server_name <your-domain>;

          ssl_certificate /etc/letsencrypt/live/<your-domain>/fullchain.pem;
          ssl_certificate_key /etc/letsencrypt/live/<your-domain>/privkey.pem;

          # Other SSL settings go here...
      }
      ```
   c. Save the file and exit the editor.
   d. Test the Nginx configuration for syntax errors:
      ```
      sudo nginx -t
      ```
   e. If there are no errors, reload Nginx to apply the changes:
      ```
      sudo systemctl reload nginx
      ```
3. **Configure Firewall Rules:**
   Ensure that your Azure VM's network security group allows incoming traffic on port 443 (HTTPS).
4. **Update DNS Records:**
   Update your DNS records to point to your Azure VM's public IP address if you haven't already.
5. **Test HTTPS Access:**
   Open a web browser and visit your website using `https://<your-domain>`. You should now have a secure connection.
6. **Automate Certificate Renewal:**
   Let's Encrypt certificates expire after a few months. To automate the renewal process, you can set up a cron job to run Certbot's renewal command:
   ```
   sudo certbot renew --dry-run
   ```
   This command checks if renewal is necessary and renews certificates if required. You can add it to the crontab file to run regularly.

That's it! Your React application on your Azure VM should now be accessible over HTTPS. Make sure to keep your SSL/TLS certificate up to date and follow security best practices to secure your application.

- Setup https
  - https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04
  - https://www.linode.com/docs/guides/ssl-apache2-debian-ubuntu/
  - Free domain - http://www.freenom.com/en/index.html


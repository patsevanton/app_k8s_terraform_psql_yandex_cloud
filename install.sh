#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

# Check command available yc terraform kubectl helm
list_command_available=(yc terraform kubectl helm)

for i in ${list_command_available[*]}
do
    if ! command -v $i &> /dev/null
    then
        echo "$i could not be found"
        exit 1
    fi
done

if yc config list | grep -q 'token'; then
  echo "yc configured. Passed"
else
  echo "yc doesn't configured."
  echo "Please run 'yc init'"
  exit 1
fi

cd terraform-k8s-mdb
yc config list > private.auto.tfvars
sed -i 's/:/=/g' private.auto.tfvars
sed '/compute-default-zone/d' -i private.auto.tfvars
sed 's/ //g' -i private.auto.tfvars
terraform apply -auto-approve
mkdir -p /home/$USER/.kube
terraform output kubeconfig > /home/$USER/.kube/config
cd ..

# Create ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --version 3.36.0  
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
sed 's/:/=/g' -i private.auto.tfvars
sed '/compute-default-zone/d' -i private.auto.tfvars
sed 's/ //g' -i private.auto.tfvars
sed 's/$/"/' -i private.auto.tfvars
sed 's/=/="/g' -i private.auto.tfvars
terraform init
terraform apply -auto-approve
mkdir -p /home/$USER/.kube
terraform output kubeconfig > /home/$USER/.kube/config
sed '/EOT/d' -i /home/$USER/.kube/config

# Создаем  ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --version 3.36.0  

# Получение External IP (внешнего IP) Kubernetes сервиса nginx-ingress-ingress-nginx-controller
export IP=$(kubectl get services nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Создание переменных DBPASS and DBHOST из terraform output. 
export DBHOST=$(terraform output dbhosts | sed -e 's/^"//' -e 's/"$//')
export DBPASS=$(terraform output dbpassword | sed -e 's/^"//' -e 's/"$//')

# Установка flask-postgres используя helm
export URL=flask-postgres.$IP.sslip.io
helm install --set DBPASS=$DBPASS,DBHOST=$DBHOST,ingress.enabled=true,ingress.hosts[0].host=$URL,ingress.hosts[0].paths[0].path=/ flask-postgres ./flask-postgres
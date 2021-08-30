# Установка Managed Service for PostgreSQL и Managed Service for Kubernetes в Yandex Cloud c помощью terraform
# Развертывание приложения в Managed Service for Kubernetes в Yandex Cloud 

Диаграмма сервисов

![](https://habrastorage.org/webt/7n/lv/pq/7nlvpq3fhuv30zifhn6rwuj5jpw.png)

# Create ingress
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --version 3.36.0  
```



# Get External IP of a Kubernetes service
```
export IP=$(kubectl get services nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

# Get DBPASS and DBHOST
```
export DBHOST=$(terraform output dbhosts | sed -e 's/^"//' -e 's/"$//')
export DBPASS=$(terraform output dbpassword | sed -e 's/^"//' -e 's/"$//')
```

# Install flask-postgres
```
URL=flask-postgres.$IP.sslip.io
helm install --set DBPASS=$DBPASS,DBHOST=$DBHOST,ingress.enabled=true,ingress.hosts[0].host=$URL,ingress.hosts[0].paths[0].path=/ flask-postgres ./flask-postgres
```


# Проверка подключения из kubernetes в PostgreSQL
```
kubectl run pgsql-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=$DBPASS" --command -- psql  --host $DBHOST -U user_name -d db_name -p 6432
```

# Установка и использование Managed Service for PostgreSQL и Managed Service for Kubernetes в Yandex Cloud c помощью terraform

В этом посте будет описана установка Managed Service for PostgreSQL и Managed Service for Kubernetes в Yandex Cloud c помощью terraform. В Kubernetes будет установлено простое приложение на flask, которая записывает данные в Managed Service for PostgreSQL. Приложение на flask описано в helm чарте и будет установлено с помощью helm. Внешний трафик из интернета будет проходить сначала Network load balancer, затем попадать в Ingress. Ingress – это ресурс для добавления правил маршрутизации трафика из внешних источников в службы в кластере kubernetes.

Диаграмма сервисов

![](https://habrastorage.org/webt/zf/l9/7r/zfl97rfszbckd9tipns_5zjfgca.png)

# Создаем ingress
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --version 3.36.0  
```

# Получение External IP (внешнего IP) Kubernetes сервиса nginx-ingress-ingress-nginx-controller
```
export IP=$(kubectl get services nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

# Создание переменных DBPASS and DBHOST из terraform output
```
export DBHOST=$(terraform output dbhosts | sed -e 's/^"//' -e 's/"$//')
export DBPASS=$(terraform output dbpassword | sed -e 's/^"//' -e 's/"$//')
```

# Установка flask-postgres используя helm
```
URL=flask-postgres.$IP.sslip.io
helm install --set DBPASS=$DBPASS,DBHOST=$DBHOST,ingress.enabled=true,ingress.hosts[0].host=$URL,ingress.hosts[0].paths[0].path=/ flask-postgres ./flask-postgres
```


# Проверка подключения из kubernetes в PostgreSQL
```
kubectl run pgsql-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=$DBPASS" --command -- psql  --host $DBHOST -U user_name -d db_name -p 6432
```

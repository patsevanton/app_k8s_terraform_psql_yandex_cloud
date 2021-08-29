# Установка Managed Service for PostgreSQL и Managed Service for Kubernetes в Yandex Cloud c помощью terraform
# Развертывание приложения в Managed Service for Kubernetes в Yandex Cloud 

# Check connect from k8s to PostgreSQL
```
kubectl run pgsql-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=your_password" --command -- psql  --host rc1c-0h7bdpqb6zeq7qon.mdb.yandexcloud.net -U user_name -d db_name -p 6432
```

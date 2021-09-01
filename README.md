# Установка и использование Managed Service for PostgreSQL и Managed Service for Kubernetes в Yandex Cloud c помощью terraform

В этом посте будет описана установка [Managed Service for PostgreSQL](https://cloud.yandex.ru/services/managed-postgresql) и [Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes) в [Yandex Cloud](https://cloud.yandex.ru/) c помощью [terraform](https://www.terraform.io/). В [Kubernetes](https://kubernetes.io/ru/) будет установлено простое приложение на [flask](https://flask.palletsprojects.com/en/2.0.x/), которая записывает данные в Managed Service for PostgreSQL. Приложение на flask описано в [helm](https://helm.sh/) чарте и будет установлено с помощью helm. Внешний трафик из интернета будет проходить сначала [Network load balancer](https://cloud.yandex.ru/services/network-load-balancer), затем попадать в [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). Ingress – это ресурс для добавления правил маршрутизации трафика из внешних источников в службы в кластере kubernetes.

Всю установка и настройка добавлена в скрипт install.sh. Можно просто запустить скрипт и все установиться. В посте описывается более подробно.

<cut />

Диаграмма сервисов

![](https://habrastorage.org/webt/zf/l9/7r/zfl97rfszbckd9tipns_5zjfgca.png)

## Необходимо чтобы были установлены следующие программы
Можно установить все перечислинные утилиты с помощью утилиты [binenv](https://github.com/devops-works/binenv), кроме Yandex.Cloud (CLI) и git.
- [yc](https://cloud.yandex.ru/docs/cli/operations/install-cli)
- terraform
- kubectl
- helm
- git

## Необходимо инициализировать Yandex.Cloud и получить приватные токены
```
yc init
```

# Клонируем репо
```
git clone https://github.com/patsevanton/app_k8s_terraform_psql_yandex_cloud.git
```

# Установка всего стенда с помощью скрипта install.sh
Для изменения конфигурации инфстраструктуры необходимо править файлы .tf. Запускаем скрипт install.sh
```
./install.sh
```

# Рассмотрим что делает скрипт install.sh. Прохождение всех этапов скрипта вручную

`set -o errexit` означает, что если какая-либо из команд в вашем коде не работает по какой-либо причине, весь скрипт терпит неудачу.

`set -o pipefail` скрипт завершится неудачно, если одна из ваших команд конвейера не удалась, в противном случае вы можете получить неправильные коды выхода, когда вы используете код конвейера.

`set -o nounset` скрипт завершится неудачно, если какая-либо из ваших переменных не установлена

# Проверка доступности команд yc terraform kubectl helm
```
list_command_available=(yc terraform kubectl helm)

for i in ${list_command_available[*]}
do
    if ! command -v $i &> /dev/null
    then
        echo "$i could not be found"
        exit 1
    fi
done
```

# Проверка что Yandex.Cloud (CLI) сконфигурирован
```
if yc config list | grep -q 'token'; then
  echo "yc configured. Passed"
else
  echo "yc doesn't configured."
  echo "Please run 'yc init'"
  exit 1
fi
```

## Установка Managed Service for PostgreSQL и Managed Service for Kubernetes в Yandex Cloud c помощью terraform
Переходим в директорию terraform-k8s-mdb
```
cd terraform-k8s-mdb
```
# Экспорт токенов из Yandex.Cloud (CLI) в private.auto.tfvars
```
yc config list > private.auto.tfvars
sed 's/:/=/g' -i private.auto.tfvars
sed '/compute-default-zone/d' -i private.auto.tfvars
sed 's/ //g' -i private.auto.tfvars
sed 's/$/"/' -i private.auto.tfvars
sed 's/=/="/g' -i private.auto.tfvars
```

# Инициализация и применение конфигурации terraform
```
terraform init
terraform apply -auto-approve
```

# Формирование kubernetes конфига из вывода terraform output kubeconfig
```
mkdir -p /home/$USER/.kube
terraform output kubeconfig > /home/$USER/.kube/config
sed '/EOT/d' -i /home/$USER/.kube/config
```

## Создаем файл private.auto.tfvars и создаем .kube/config
В файле записываем ваши `token`, `cloud-id`, `folder-id` полученые из `yc init`
```
terraform apply
mkdir -p /home/$USER/.kube
terraform output kubeconfig > /home/$USER/.kube/config
```

Kubernetes config внутри terraform создается с помощью вот такого кода:
```
locals {
  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${yandex_kubernetes_cluster.zonal_k8s_cluster.master[0].external_v4_endpoint}
    certificate-authority-data: ${base64encode(yandex_kubernetes_cluster.zonal_k8s_cluster.master[0].cluster_ca_certificate)}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: yc
  name: ycmk8s
current-context: ycmk8s
users:
- name: yc
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: yc
      args:
      - k8s
      - create-token
KUBECONFIG
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}
```

## Создаем ingress
```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx && helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --version 3.36.0  
```
Устанавливаем версию 3.36.0, так как последняя версия поддерживает только Kubernetes версии >= v1.19

### Получение External IP (внешнего IP) Kubernetes сервиса nginx-ingress-ingress-nginx-controller
```
export IP=$(kubectl get services nginx-ingress-ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

## Создание переменных DBPASS and DBHOST из terraform output. Делаем в директории terraform-k8s-mdb
```
export DBHOST=$(terraform output dbhosts | sed -e 's/^"//' -e 's/"$//')
export DBPASS=$(terraform output dbpassword | sed -e 's/^"//' -e 's/"$//')
cd ..
```

## Установка flask-postgres используя helm
```
URL=flask-postgres.$IP.sslip.io
helm install --set DBPASS=$DBPASS,DBHOST=$DBHOST,ingress.enabled=true,ingress.hosts[0].host=$URL,ingress.hosts[0].paths[0].path=/ flask-postgres ./flask-postgres
```

## Проверка подключения из kubernetes в PostgreSQL (Вручную. После выполнения скрипта install.sh)
```
cd terraform-k8s-mdb
export DBHOST=$(terraform output dbhosts | sed -e 's/^"//' -e 's/"$//')
export DBPASS=$(terraform output dbpassword | sed -e 's/^"//' -e 's/"$//')
cd ..
kubectl run pgsql-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:11.7.0-debian-10-r9 --env="PGPASSWORD=$DBPASS" --command -- psql  --host $DBHOST -U user_name -d db_name -p 6432
```

Заходим в приложение flask-postgres по адресу, который был указан в консоли.

![](https://habrastorage.org/webt/vh/y4/pt/vhy4ptdn5lismhu85lhlfkgumdi.png)

Вводим тестовые данные
![](https://habrastorage.org/webt/jh/yu/ov/jhyuovzf5w8vth250-e6bn_1zgq.png)

Данные успешно добавились. Значит приложение работает и подключение к PostgreSQL тоже работает.

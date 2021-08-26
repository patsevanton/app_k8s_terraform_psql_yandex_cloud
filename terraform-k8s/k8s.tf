# yandex_kubernetes_cluster

resource "yandex_kubernetes_cluster" "zonal_cluster_resource_name" {
  name        = "my-cluster"
  description = "my-cluster description"
  network_id = "${yandex_vpc_network.this.id}"

  master {
    version = "1.18"
    zonal {
      zone      = "${yandex_vpc_subnet.subnet_resource_name.zone}"
      subnet_id = "${yandex_vpc_subnet.subnet_resource_name.id}"
    }
    public_ip = true
  }

  service_account_id      = "${yandex_iam_service_account.this.id}"
  node_service_account_id = "${yandex_iam_service_account.this.id}"
  release_channel = "STABLE"
  depends_on = [yandex_resourcemanager_folder_iam_member.this]
}

# yandex_kubernetes_node_group

resource "yandex_kubernetes_node_group" "my_node_group" {
  cluster_id  = "${yandex_kubernetes_cluster.zonal_cluster_resource_name.id}"
  name        = "name"
  description = "description"
  version     = "1.18"

  labels = {
    "key" = "value"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat                = true
      subnet_ids         = ["${yandex_vpc_subnet.subnet_resource_name.id}"]
      security_group_ids = ["${yandex_vpc_security_group.my_sg.id}"]
    }

    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      type = "network-hdd"
      size = 32
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-c"
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  }
}

resource "yandex_vpc_security_group" "my_sg" {
  name           = "My security group"
  description    = "description for my security group"
  network_id     = yandex_vpc_network.this.id

  ingress {
    protocol       = "TCP"
    description    = "ingress"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = "6432"
  }

}

resource "yandex_vpc_network" "this" {}

resource "yandex_vpc_subnet" "subnet_resource_name" {
  network_id     = yandex_vpc_network.this.id
  zone = "ru-central1-c"
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_iam_service_account" "this" {
  name = "k8-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "this" {
  folder_id = var.yc_folder_id

  member = "serviceAccount:${yandex_iam_service_account.this.id}"
  role   = "editor"
}

locals {
  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${yandex_kubernetes_cluster.zonal_cluster_resource_name.master[0].external_v4_endpoint}
    certificate-authority-data: ${base64encode(yandex_kubernetes_cluster.zonal_cluster_resource_name.master[0].cluster_ca_certificate)}
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

resource "yandex_kubernetes_cluster" "zonal_cluster_resource_name" {
  name        = "my-cluster"
  description = "my-cluster description"
  network_id = "${yandex_vpc_network.this.id}"

  master {
    version = "1.17"
    zonal {
      zone      = "${yandex_vpc_subnet.subnet_resource_name.zone}"
      subnet_id = "${yandex_vpc_subnet.subnet_resource_name.id}"
    }
    public_ip = true
  }

  service_account_id      = "${yandex_iam_service_account.this.id}"
  node_service_account_id = "${yandex_iam_service_account.this.id}"
  release_channel = "STABLE"
  depends_on = ["yandex_resourcemanager_folder_iam_member.this"]
}

resource "yandex_vpc_network" "this" {}

resource "yandex_vpc_subnet" "subnet_resource_name" {
  network_id     = yandex_vpc_network.this.id
  zone = "ru-central1-a"
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_iam_service_account" "this" {
  name = "k8-sa"
}

resource "yandex_resourcemanager_folder_iam_member" "this" {
  folder_id = var.folder-id

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

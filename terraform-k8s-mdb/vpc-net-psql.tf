resource "yandex_vpc_network" "k8s-mdb-network" {
  name = "k8s-network"
}

resource "yandex_vpc_subnet" "k8s-mdb-subnet" {
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.k8s-mdb-network.id
  v4_cidr_blocks = ["10.5.0.0/24"]
  depends_on = [
    yandex_vpc_network.k8s-mdb-network,
  ]
}

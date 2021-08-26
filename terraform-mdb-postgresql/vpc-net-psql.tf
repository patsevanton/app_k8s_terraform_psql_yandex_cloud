resource "yandex_vpc_network" "postgresql-single" {}

resource "yandex_vpc_subnet" "postgresql-single" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.postgresql-single.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-c"
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]

  depends_on = [
    yandex_vpc_network.network-1,
  ]

}
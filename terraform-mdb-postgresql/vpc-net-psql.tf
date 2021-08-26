resource "yandex_vpc_network" "vpc-psql" {}

resource "yandex_vpc_subnet" "subnet-psql" {
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.vpc-psql.id
  v4_cidr_blocks = ["10.5.0.0/24"]
  depends_on = [
    yandex_vpc_network.vpc-psql,
  ]
}

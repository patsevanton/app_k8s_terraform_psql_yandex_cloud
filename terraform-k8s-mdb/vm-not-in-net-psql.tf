resource "yandex_iam_service_account" "single-vm" {
  name        = "single-vm"
  description = "service account to manage IG"
}

resource "yandex_resourcemanager_folder_iam_binding" "single-vm" {
  folder_id   = var.folder-id
  role        = "editor"
  members     = [
    "serviceAccount:${yandex_iam_service_account.single-vm.id}",
  ]
  depends_on = [
    yandex_iam_service_account.single-vm,
  ]
}

resource "yandex_compute_instance_group" "vm-not-in-net-psql" {
  name               = "vm-not-in-net-psql"
  folder_id          = var.folder-id
  service_account_id = yandex_iam_service_account.single-vm.id

  depends_on = [
    yandex_iam_service_account.single-vm,
    yandex_resourcemanager_folder_iam_binding.single-vm,
    yandex_vpc_network.network-1,
    yandex_vpc_subnet.subnet-1,
  ]

  instance_template {

    # Имя виртуальных машин, создаваемых Instance Groups
    name = "vm-not-in-net-psql-{instance.index}"

    platform_id = "standard-v1"
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd8vmcue7aajpmeo39kk" # Ubuntu 20.04 LTS
        size     = 10
      }
    }

    network_interface {
      network_id = yandex_vpc_network.network-1.id
      subnet_ids = [yandex_vpc_subnet.subnet-1.id]
      # Флаг nat true указывает что виртуалкам будет предоставлен публичный IP адрес.
      nat = true
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    }
    network_settings {
      type = "STANDARD"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

  allocation_policy {
    zones = ["ru-central1-c"]
  }

  deploy_policy {
    max_unavailable = 1
    max_creating    = 1
    max_expansion   = 1
    max_deleting    = 1
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]

  depends_on = [
    yandex_vpc_network.network-1,
  ]

}

# Output values

output "instance_group_vm_not_in_net_psql_public_ips" {
  description = "Public IP addresses for vm-not-in-net-psql"
  value = yandex_compute_instance_group.vm-not-in-net-psql.instances.*.network_interface.0.nat_ip_address
}

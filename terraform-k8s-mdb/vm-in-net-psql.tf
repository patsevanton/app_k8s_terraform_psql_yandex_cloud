resource "yandex_compute_instance_group" "vm-in-net-psql" {
  name               = "vm-in-net-psql"
  folder_id          = var.folder-id
  service_account_id = yandex_iam_service_account.this.id

  depends_on = [
    yandex_iam_service_account.this,
    yandex_resourcemanager_folder_iam_binding.editor,
    yandex_vpc_network.k8s-mdb-network,
    yandex_vpc_subnet.k8s-mdb-subnet,
  ]

  instance_template {

    # Имя виртуальных машин, создаваемых Instance Groups
    name = "vm-in-net-psql-{instance.index}"

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
      network_id = yandex_vpc_network.k8s-mdb-network.id
      subnet_ids = [yandex_vpc_subnet.k8s-mdb-subnet.id]
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

# Output values

output "instance_group_vm_in_net_psql_public_ips" {
  description = "Public IP addresses for vm-in-net-psql"
  value = yandex_compute_instance_group.vm-in-net-psql.instances.*.network_interface.0.nat_ip_address
}

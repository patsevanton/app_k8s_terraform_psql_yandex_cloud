resource "yandex_iam_service_account" "ig-sa" {
  name        = "ig-sa"
  description = "service account to manage IG"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id   = var.yc_folder_id
  role        = "editor"
  members     = [
    "serviceAccount:${yandex_iam_service_account.ig-sa.id}",
  ]
  depends_on = [
    yandex_iam_service_account.ig-sa,
  ]
}

resource "yandex_compute_instance_group" "vm-in-net-psql" {
  name               = "vm-in-net-psql"
  folder_id          = var.yc_folder_id
  service_account_id = "${yandex_iam_service_account.ig-sa.id}"

  depends_on = [
    yandex_iam_service_account.ig-sa,
    yandex_resourcemanager_folder_iam_binding.editor,
    yandex_vpc_network.vpc-psql,
    yandex_vpc_subnet.subnet-psql,
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
      network_id = "${yandex_vpc_network.vpc-psql.id}"
      subnet_ids = ["${yandex_vpc_subnet.subnet-psql.id}"]
    }

    metadata = {
      ssh-keys = "ubuntu:${file("~/.ssh/id_rsa_epam.pub")}"
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

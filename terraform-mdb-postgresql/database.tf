resource "yandex_mdb_postgresql_cluster" "postgresql-single" {
  name        = "test"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.postgresql-single.id

  config {
    version = 12
    resources {
      resource_preset_id = "s2.micro"
      disk_type_id       = "network-ssd"
      disk_size          = 16
    }
    postgresql_config = {
      max_connections                   = 395
      enable_parallel_hash              = true
      vacuum_cleanup_index_scale_factor = 0.2
      autovacuum_vacuum_scale_factor    = 0.34
      default_transaction_isolation     = "TRANSACTION_ISOLATION_READ_COMMITTED"
      shared_preload_libraries          = "SHARED_PRELOAD_LIBRARIES_AUTO_EXPLAIN,SHARED_PRELOAD_LIBRARIES_PG_HINT_PLAN"
    }
  }

  maintenance_window {
    type = "WEEKLY"
    day  = "SAT"
    hour = 12
  }

  database {
    name  = "db_name"
    owner = "user_name"
  }

  user {
    name       = "user_name"
    password   = "your_password"
    conn_limit = 50
    permission {
      database_name = "db_name"
    }
    settings = {
      default_transaction_isolation = "read committed"
      log_min_duration_statement    = 5000
    }
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.postgresql-single.id
  }
}

resource "yandex_vpc_network" "postgresql-single" {}

resource "yandex_vpc_subnet" "postgresql-single" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.postgresql-single.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}

locals {
  dbuser = tolist(yandex_mdb_postgresql_cluster.postgresql-single.user.*.name)[0]
  dbpassword = tolist(yandex_mdb_postgresql_cluster.postgresql-single.user.*.password)[0]
  dbhosts = yandex_mdb_postgresql_cluster.postgresql-single.host.*.fqdn
  dbname = tolist(yandex_mdb_postgresql_cluster.postgresql-single.database.*.name)[0]
  dburi = "postgresql://${local.dbuser}:${local.dbpassword}@:1/${local.dbname}"
}

output "dbuser" {
  value = "${local.dbuser}"
}

output "dbpassword" {
  value = "${local.dbpassword}"
  sensitive = true
}

output "dbhosts" {
  value = "${local.dbhosts}"
}

output "dbname" {
  value = "${local.dbname}"
}

output "dburi" {
  value = "${local.dburi}"
  sensitive = true
}

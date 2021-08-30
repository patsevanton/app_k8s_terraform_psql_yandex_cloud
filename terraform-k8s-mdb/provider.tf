# Variables

variable "token" {
  type = string
  description = "Yandex Cloud API key"
}

variable "cloud-id" {
  type = string
  description = "Yandex Cloud id"
}

variable "folder-id" {
  type = string
  description = "Yandex Cloud folder id"
}

# Provider

terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.61.0"
    }
  }
}

provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud-id
  folder_id = var.folder-id
}

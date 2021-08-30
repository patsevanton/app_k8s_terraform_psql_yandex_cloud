# Service accounts

resource "yandex_iam_service_account" "this" {
  name = "this"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = var.folder-id
  role = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.this.id}"
  ]
  depends_on = [
    yandex_iam_service_account.this,
  ]
}

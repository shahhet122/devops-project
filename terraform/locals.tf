locals {
  storage_account_tier             = "Standard"
  stroage_account_replication_type = "LRS"
  storage_account_https_traffic_only = true
  storage_container_access_type    = "private"

  keyvault_sku                     = "standard"
}

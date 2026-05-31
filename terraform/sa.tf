resource "azurerm_storage_account" "sa" {
  name                = join("", [var.STORAGE_NAME, tostring(random_integer.suffix.result)])
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  account_tier             = local.storage_account_tier
  account_replication_type = local.stroage_account_replication_type

  enable_https_traffic_only = local.storage_account_https_traffic_only

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_storage_container" "images" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = local.storage_container_access_type
}

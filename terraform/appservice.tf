resource "azurerm_service_plan" "plan" {
  name                = var.APP_SERVICE_PLAN_NAME
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type  = "Linux"
  sku_name = "F1"
}

resource "azurerm_linux_web_app" "app" {
  name                = join("", [var.APP_SERVICE_NAME, tostring(random_integer.suffix.result)])
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  identity {
    type = "SystemAssigned"
  }

  site_config {}

  app_settings = {
    "STORAGE_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection_string.id})"
    "STORAGE_CONTAINER_NAME"    = azurerm_storage_container.images.name
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

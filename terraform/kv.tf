resource "azurerm_key_vault" "kv" {
  name                = join("", [var.KEYVAULT_NAME, tostring(random_integer.suffix.result)])
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  tenant_id = var.TF_VAR_TENANT_ID
  sku_name  = local.keyvault_sku

  access_policy {
    tenant_id = var.TF_VAR_TENANT_ID
    object_id = var.DEPLOYER_OBJECT_ID

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]
  }
}

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.sa.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
}

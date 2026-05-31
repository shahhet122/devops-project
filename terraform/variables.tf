variable "TF_VAR_TENANT_ID" {
  type        = string
  description = "id of the tenant to use."
}

variable "TF_VAR_SUBSCRIPTION_ID" {
  type        = string
  description = "id of the subscription to use."
}

variable "LOCATION" {
  type        = string
  description = "Location of all resources."
}

variable "RESOURCE_GROUP_NAME" {
  type        = string
  description = "Name of the resource group."
}

variable "STORAGE_NAME" {
  type        = string
  description = "Name of the storage account (must be globally unique, lowercase, 3-24 chars)."
}

variable "KEYVAULT_NAME" {
  type        = string
  description = "Name of the key vault (must be globally unique, 3-24 chars)."
}

variable "DEPLOYER_OBJECT_ID" {
  type        = string
  description = "Object ID of the user running Terraform (az ad signed-in-user show --query id -o tsv)."
}

variable "APP_SERVICE_PLAN_NAME" {
  type        = string
  description = "Name of the app service plan."
}

variable "APP_SERVICE_NAME" {
  type        = string
  description = "Name of the web app (must be globally unique)."
}

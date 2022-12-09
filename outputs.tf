output "resource_group" {
  value = azurerm_resource_group.bootstrap_rg.name
}

output "storage_account_access_key" {
  value     = azurerm_storage_account.core_store.primary_access_key
  sensitive = true
}

output "storage_account_name" {
  value = azurerm_storage_account.core_store.name
}

output "storage_container_name" {
  value = azurerm_storage_container.terraform_container.name
}

output "required_tags" {
  value = local.tags
}
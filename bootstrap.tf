locals {
  tags = {
    environment = "dev"
    createdby   = "terraform"
  }
}

resource "azurerm_resource_group" "bootstrap_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = local.tags
}

resource "azurerm_storage_account" "core_store" {
  account_replication_type        = "LRS"
  account_tier                    = "Standard"
  location                        = var.location
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.bootstrap_rg.name
  allow_nested_items_to_be_public = true

  tags = local.tags
}

resource "azurerm_storage_container" "terraform_container" {
  name                  = "terraform"
  storage_account_name  = azurerm_storage_account.core_store.name
  container_access_type = "private"
}

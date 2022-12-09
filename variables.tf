variable "storage_account_name" {
  type        = string
  description = "Storage account name where terraform state will be placed"
}

variable "location" {
  type        = string
  description = "Location of resource group and storage account"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
}
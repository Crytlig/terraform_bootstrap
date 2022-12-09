# Bootstrap Terraform with Terraform

Bootstrap Terraform using Terraform.

Change the following values in [bootstrap.sh](bootstrap.sh)

```bash
# Storage account for keeping state files
storage_account_name=""  
# Location of storage account and resource group
location=""
# Resource group name
resource_group_name=""
# Blob container name in storage account
container_name=""
# State file name
key=""
```

For example:

```bash
storage_account_name="thishastobeunique"
location="westeurope"
resource_group_name="myterraformrg"
container_name="terraform"
key="tfstate.core"
```

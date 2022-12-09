#!/bin/bash

set -e

# Bootstrapping variables
storage_account_name="tstbootsdstr"
location="westeurope"
resource_group_name="tst-bootstrap"
container_name="terraform"
key="terraform.core"

export TF_VAR_storage_account_name="$storage_account_name"
export TF_VAR_location="$location"
export TF_VAR_resource_group_name="$resource_group_name"
export TF_VAR_container_name="$container_name"
export TF_VAR_key="$key"

# Comment the backend so we can use a local state file
sed -i 's/backend/## backend/g' provider.tf

echo "######################"
echo "######################"
echo "# ACTIVATING STAGE 1 #"
echo "######################"
echo "######################"

echo -e "\n"

# Initial init
terraform init

echo -e "\n\n"
echo "# INITIAL PROVISIONING  #"

# Initial apply
terraform apply --auto-approve

# Replace local backend with azure
sed -i 's/##//g' provider.tf

# Get the access key for the storage account
access_key=$(cat terraform.tfstate | jq -r .outputs.storage_account_access_key.value)

echo -e "\n\n"
echo "# ACTIVATING STAGE 2 #"

# Second init with file
terraform init \
  -backend-config="storage_account_name=$storage_account_name" \
  -backend-config="container_name=$container_name" \
  -backend-config="key=$key" \
  -backend-config="access_key=$access_key" \
  -force-copy

echo -e "\n\n"
echo "# SECOND  PROVISIONING #"

# Second apply
terraform apply --auto-approve

echo "
#########################################################
### REFER TO THE NEW REMOTE STATE USING THE FOLLOWING ###
#########################################################

#### PLEASE USE VARIABLES, NOT THE HARDCODED VALUES #####

data \"terraform_remote_state\" \"core\" {
  backend = \"azurerm\"

  config = {
    container_name = $container_name
    storage_account_name = $storage_account_name
    key = $key
    access_key = $access_key
   } 
}
"

echo "OUPUTTING VARIABLES TO: backend.tfvars."

if [ -f "./backend.tfvars" ]; then rm backend.tfvars; fi

{
  echo "container_name = \"${container_name}\""
  echo "storage_account_name = \"${storage_account_name}\""
  echo "key = \"${key}\""
  echo "access_key = \"${access_key}\""
} >> backend.tfvars

terraform fmt

# Remove old files if needed
# rm -rf .terraform* && rm terraform.*
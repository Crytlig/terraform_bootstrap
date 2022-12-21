#!/bin/bash

set -e

usage="$(basename "$0") [-h] [-l location] [-g resource_group_name] [-s storage_account_name] [-c container_name] [-k key]
Creates a Terraform bootstrap using Terraform
where:
    -h  show this help text
    -l  desired location of resource group and storage account
    -g  desired resource group name
    -c  container name within storage account
    -k  storage state file name. Defaults to 'bootstrap'
"

while getopts h:l:g:c:k:s: flag
do
    case "${flag}" in
        h) echo "$usage"; exit;;
        l) location=${OPTARG};;
        g) resource_group_name=${OPTARG};;
        s) storage_account_name=${OPTARG};;
        c) container_name=${OPTARG};;
        k) key=${OPTARG};;
        :) printf "Missing argument for -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
        \?) printf "Illegal option: -%s\n" "$OPTARG" >&2; echo "$usage" >&2; exit 1;;
    esac
done

# mandatory arguments
if [ ! "$location" ] || [ ! "$resource_group_name" ] || [ ! "$container_name" ] || [ ! "$storage_account_name" ]; then
  echo "All arguments must be provided (key defaults to 'bootstrap')"
  echo
  echo "$usage" >&2; exit 1
fi

key=${key-"bootstrap"}
storage_account_name=$(echo "${storage_account_name}" | tr '[:upper:]' '[:lower:]')$RANDOM


echo "Arguments provided:"
echo "Location: $location";
echo "Resource Group Name: $resource_group_name";
echo "Storage Account Name: $storage_account_name";
echo "Container Name: $container_name";
echo "Key: $key";

export TF_VAR_storage_account_name="$storage_account_name"
export TF_VAR_location="$location"
export TF_VAR_resource_group_name="$resource_group_name"
export TF_VAR_container_name="$container_name"
export TF_VAR_key="$key"

# Comment the backend so we can use a local state file
sed -i 's/backend/## backend/g' provider.tf


echo "######################"
echo "# ACTIVATING STAGE 1 #"
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

echo "######################"
echo "# ACTIVATING STAGE 2 #"
echo "######################"

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

echo "OUPUTTING VARIABLES TO: backend.tfvars"
echo "COPY THIS FILE AND USE WHEN DOING TERRAFORM INIT"
echo "REMEMBER TO CHANGE THE FOLLOWING IN YOUR OWN CONFIG 
backend \"azurerm\" {
    container_name = \"YOURNEWSTATEFILENAME\"
  }
"

if [ -f "./backend.tfvars" ]; then rm backend.tfvars; fi

{
  echo "container_name = \"${container_name}\""
  echo "storage_account_name = \"${storage_account_name}\""
  echo "key = \"${key}\""
  echo "access_key = \"${access_key}\""
} >> backend.tfvars

terraform fmt
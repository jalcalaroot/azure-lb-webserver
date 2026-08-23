# Remote backend in Azure Blob Storage, managed by the azure-tfstate-bootstrap
# project. The storage account and container already exist (not managed by
# this module, to avoid the chicken-and-egg problem with state). Locking is
# native via blob lease.
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatejohanaks"
    container_name       = "tfstate"
    key                  = "lb-webserver/terraform.tfstate"
  }
}

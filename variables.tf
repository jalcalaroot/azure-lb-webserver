variable "subscription_id" {
  description = "Azure subscription ID - required explicitly by the azurerm provider >= 4.0. No default on purpose: pass it via -var, a gitignored .tfvars, or the TF_VAR_subscription_id environment variable"
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group where the network project (azure-virtual-network) lives"
  type        = string
  default     = "rg-network"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralus"
}

variable "vnet_name" {
  description = "Name of the existing VNet"
  type        = string
  default     = "vnet-ha"
}

variable "app_subnet_name" {
  description = "Existing app subnet shared by all webserver instances (regional, not per-AZ - HA comes from the VM zone assignment, not from separate subnets)"
  type        = string
  default     = "snet-app"
}

variable "web_instance_count" {
  description = "Number of Nginx instances in the backend pool"
  type        = number
  default     = 2
}

variable "prefix" {
  description = "Prefix used to name this project's resources"
  type        = string
  default     = "appgw-web"
}

variable "vm_size" {
  description = "Webserver VM size (matches the jumpbox project's choice - reliable zonal capacity in centralus)"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "VM admin username"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Local path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "enable_waf" {
  description = "If true, deploys WAF_v2 instead of Standard_v2"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags, aligned with the existing network project"
  type        = map(string)
  default = {
    environment = "production"
    project     = "ha-vnet"
    managed_by  = "terraform"
  }
}

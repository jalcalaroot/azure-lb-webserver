data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

# Single regional app subnet, shared by all webserver instances. HA comes
# from the "zones" argument on each VM, not from one subnet per AZ - see
# azure-virtual-network's CLAUDE.md for the reasoning. All instances share
# the "nsg-private" NSG and the shared NAT Gateway.
data "azurerm_subnet" "app" {
  name                 = var.app_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

# Application Gateway subnet, created in the azure-virtual-network project
# (along with its NSG "nsg-appgw").
data "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

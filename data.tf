data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}

# Una app subnet existente por instancia: VM 1 -> snet-app-az1,
# VM 2 -> snet-app-az2 (ver var.app_subnet_names). Todas comparten
# el NSG "nsg-private" y el NAT Gateway compartido.
data "azurerm_subnet" "app" {
  count                = length(var.app_subnet_names)
  name                 = var.app_subnet_names[count.index]
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

# Subnet de Application Gateway, creada en el proyecto
# azure-virtual-network (junto con su NSG "nsg-appgw").
data "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

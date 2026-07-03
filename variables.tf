variable "resource_group_name" {
  description = "Resource Group existente donde vive vnet-ha"
  type        = string
  default     = "johan"
}

variable "location" {
  description = "Region de Azure"
  type        = string
  default     = "centralus"
}

variable "vnet_name" {
  description = "Nombre del VNet existente"
  type        = string
  default     = "vnet-ha"
}

variable "app_subnet_names" {
  description = "Lista de app subnets existentes, una por instancia (VM 1 -> az1, VM 2 -> az2, etc.)"
  type        = list(string)
  default     = ["snet-app-az1", "snet-app-az2"]
}

variable "web_instance_count" {
  description = "Cantidad de instancias Nginx en el backend pool"
  type        = number
  default     = 2
}

variable "prefix" {
  description = "Prefijo para nombrar los recursos de este proyecto"
  type        = string
  default     = "appgw-web"
}

variable "vm_size" {
  description = "Tamano de la VM del webserver"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Ruta local a tu clave publica SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "enable_waf" {
  description = "Si es true, despliega WAF_v2 en vez de Standard_v2"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags comunes, alineados con el proyecto de red existente"
  type        = map(string)
  default = {
    environment = "production"
    project     = "ha-vnet"
    managed_by  = "terraform"
  }
}

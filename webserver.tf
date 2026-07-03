# 2 VMs con Nginx, una por AZ (VM 1 -> snet-app-az1, VM 2 -> snet-app-az2).
# Cada NIC va a su respectiva app subnet via data.azurerm_subnet.app[count.index].
# Comparten NSG "nsg-private" (existente) y NAT Gateway compartido para egress.

resource "azurerm_network_interface" "web_nic" {
  count               = var.web_instance_count
  name                = "${var.prefix}-nic-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.app[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "web_vm" {
  count               = var.web_instance_count
  name                = "${var.prefix}-vm-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  zone                = tostring(count.index + 1)
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.web_nic[count.index].id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # El HTML deja explicito el numero de instancia y su AZ, para
  # confirmar visualmente que el Application Gateway esta
  # repartiendo trafico entre ambas.
  custom_data = base64encode(<<-CLOUDINIT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    cat <<HTML > /var/www/html/index.html
    <html>
      <head><title>Instancia ${count.index + 1}</title></head>
      <body style="font-family: sans-serif; text-align: center; margin-top: 100px;">
        <h1>Soy la instancia ${count.index + 1}</h1>
        <p>Availability Zone: ${count.index + 1}</p>
        <p>Hostname: $(hostname)</p>
      </body>
    </html>
    HTML
  CLOUDINIT
  )
}

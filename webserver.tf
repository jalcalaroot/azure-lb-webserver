# web_instance_count Nginx VMs, all in the single regional "snet-app" subnet.
# Each VM gets an explicit "zones" argument (cycling through 1/2/3) for HA -
# Azure subnets already span all zones, so zonal spread comes from the
# resources deployed into the subnet, not from separate per-AZ subnets.

resource "azurerm_network_interface" "web_nic" {
  count               = var.web_instance_count
  name                = "${var.prefix}-nic-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.app.id
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
  zone                = tostring((count.index % 3) + 1)
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

  # The HTML makes the instance number and zone explicit, to visually
  # confirm the Application Gateway is distributing traffic across
  # instances.
  custom_data = base64encode(<<-CLOUDINIT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    cat <<HTML > /var/www/html/index.html
    <html>
      <head><title>Instance ${count.index + 1}</title></head>
      <body style="font-family: sans-serif; text-align: center; margin-top: 100px;">
        <h1>I am instance ${count.index + 1}</h1>
        <p>Availability Zone: ${(count.index % 3) + 1}</p>
        <p>Hostname: $(hostname)</p>
      </body>
    </html>
    HTML
  CLOUDINIT
  )
}

output "application_gateway_public_ip" {
  description = "IP publica del Application Gateway - probar con curl http://<esta_ip>"
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "web_vm_private_ips" {
  description = "IPs privadas de las VMs webserver, en orden (VM 1 = az1, VM 2 = az2)"
  value       = azurerm_network_interface.web_nic[*].private_ip_address
}

output "web_vm_names" {
  description = "Nombres de las VMs webserver"
  value       = azurerm_linux_virtual_machine.web_vm[*].name
}

output "application_gateway_public_ip" {
  description = "Application Gateway public IP - test with curl http://<this_ip>"
  value       = azurerm_public_ip.appgw_pip.ip_address
}

output "web_vm_private_ips" {
  description = "Webserver VM private IPs, in order (VM 1, VM 2, ...)"
  value       = azurerm_network_interface.web_nic[*].private_ip_address
}

output "web_vm_names" {
  description = "Webserver VM names"
  value       = azurerm_linux_virtual_machine.web_vm[*].name
}

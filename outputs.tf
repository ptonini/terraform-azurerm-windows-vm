output "this" {
  value = azurerm_windows_virtual_machine.this
}

output "network_interfaces" {
  value = azurerm_network_interface.this
}

output "public_ips" {
  value = [for ip in azurerm_public_ip.this : ip.ip_address]
}

output "credentials" {
  value = {
    username = azurerm_windows_virtual_machine.this[0].admin_username
    password = azurerm_windows_virtual_machine.this[0].admin_password
  }
}
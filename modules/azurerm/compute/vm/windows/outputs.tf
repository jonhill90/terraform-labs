output "vm_id" {
  description = "The ID of the created Virtual Machine"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "vm_private_ip" {
  description = "The private IP of the Virtual Machine"
  value       = azurerm_network_interface.vm_nic.private_ip_address
}
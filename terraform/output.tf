output "k3s_server_ipv4_address" {
  value = proxmox_vm_qemu.k3s_server_vm[*].default_ipv4_address
}

output "k3s_agent_ipv4_address" {
  value = proxmox_vm_qemu.k3s_agent_vm[*].default_ipv4_address
}

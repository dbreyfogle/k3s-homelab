# [[ VM Template ]]

resource "proxmox_virtual_environment_vm" "ubuntu_template" {
  name      = "ubuntu-template"
  node_name = var.node_name
  vm_id     = var.template_vm_id
  template  = true
  on_boot   = false

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    backup       = false
    size         = 75
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = var.vlan_id
  }

}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ubuntu
    users:
      - default
      - name: ubuntu
        groups:
          - sudo
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.hcp_vault_secrets_app.k3s_homelab.secrets.ssh_authorized_key_1)}
          - ${trimspace(data.hcp_vault_secrets_app.k3s_homelab.secrets.ssh_authorized_key_2)}
        sudo: ALL=(ALL) NOPASSWD:ALL
    runcmd:
        - apt update
        - apt install -y qemu-guest-agent
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
    EOF

    file_name = "cloud-config.yaml"
  }
}

# [[ K3s Servers ]]

resource "proxmox_virtual_environment_vm" "k3s_server_vm" {
  count     = var.num_servers
  name      = "k3s-server-${count.index}"
  node_name = var.node_name
  vm_id     = var.start_vm_id + count.index

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.id
  }
}

# [[ K3s Agents ]]

resource "proxmox_virtual_environment_vm" "k3s_agent_vm" {
  count     = var.num_agents
  name      = "k3s-agent-${count.index}"
  node_name = var.node_name
  vm_id     = var.start_vm_id + var.num_servers + count.index

  clone {
    vm_id = proxmox_virtual_environment_vm.ubuntu_template.id
  }
}

# [[ Ansible Inventory ]]

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.yml.tftpl", {
    server_ip = proxmox_virtual_environment_vm.k3s_server_vm[*].ipv4_addresses[1][0]
    agent_ip  = proxmox_virtual_environment_vm.k3s_agent_vm[*].ipv4_addresses[1][0]
  })
  filename        = "${path.module}/../k3s-ansible/inventory.yml"
  file_permission = "0644"
}

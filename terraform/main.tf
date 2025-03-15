# [[ Cloud-Init ]]

resource "proxmox_virtual_environment_file" "cloud_config" {
  for_each = toset(concat(
    [for i in range(var.num_servers) : "k3s-server-${i}"],
    [for i in range(var.num_agents) : "k3s-agent-${i}"],
  ))

  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    hostname: ${each.value}
    users:
      - default
      - name: root
        shell: /bin/bash
        ssh_authorized_keys:
          - ${trimspace(data.hcp_vault_secrets_app.k3s_homelab.secrets.ssh_authorized_key_1)}
          - ${trimspace(data.hcp_vault_secrets_app.k3s_homelab.secrets.ssh_authorized_key_2)}
    runcmd:
        - apt update
        - apt install -y qemu-guest-agent
        - systemctl enable qemu-guest-agent
        - systemctl start qemu-guest-agent
    EOF

    file_name = "cloud-config-${each.value}.yaml"
  }
}

resource "proxmox_virtual_environment_download_file" "cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name
  url          = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

# [[ K3s Server ]]

resource "proxmox_virtual_environment_vm" "k3s_server_vm" {
  count     = var.num_servers
  name      = "k3s-server-${count.index}"
  node_name = var.node_name
  vm_id     = var.start_vm_id + count.index
  on_boot   = false

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config["k3s-server-${count.index}"].id
  }

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
    file_id      = proxmox_virtual_environment_download_file.cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    backup       = false
    size         = 75
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = var.vlan_id
  }
}

# [[ K3s Agent ]]

resource "proxmox_virtual_environment_vm" "k3s_agent_vm" {
  count     = var.num_agents
  name      = "k3s-agent-${count.index}"
  node_name = var.node_name
  vm_id     = var.start_vm_id + var.num_servers + count.index
  on_boot   = false

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config["k3s-agent-${count.index}"].id
  }

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
    file_id      = proxmox_virtual_environment_download_file.cloud_image.id
    interface    = "scsi0"
    discard      = "on"
    ssd          = true
    backup       = false
    size         = 75
  }

  network_device {
    bridge  = "vmbr0"
    vlan_id = var.vlan_id
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

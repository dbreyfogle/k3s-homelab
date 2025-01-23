resource "proxmox_vm_qemu" "k3s_server_vm" {
  count       = var.k3s_server_num
  vmid        = var.pm_vmid_start + count.index
  name        = "k3s-server-${count.index}"
  target_node = var.pm_target_node
  clone       = var.pm_vm_template
  full_clone  = true
  boot        = "order=scsi0"
  scsihw      = "virtio-scsi-single"
  cores       = var.k3s_server_cores
  memory      = var.k3s_server_memory
  agent       = 1

  # cloud-init
  cicustom  = var.cicustom
  ciuser    = "root"
  sshkeys   = data.hcp_vault_secrets_app.k3s_homelab.secrets.ssh_keys
  ciupgrade = true
  ipconfig0 = "ip=dhcp"

  disks {
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage    = "local-lvm"
          size       = var.k3s_server_storage
          emulatessd = var.emulatessd
          discard    = var.discard
        }
      }
    }
  }
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
    tag    = var.tag
  }
}

resource "proxmox_vm_qemu" "k3s_agent_vm" {
  count       = var.k3s_agent_num
  vmid        = var.pm_vmid_start + var.k3s_server_num + count.index
  name        = "k3s-agent-${count.index}"
  target_node = var.pm_target_node
  clone       = var.pm_vm_template
  full_clone  = true
  boot        = "order=scsi0"
  scsihw      = "virtio-scsi-single"
  cores       = var.k3s_agent_cores
  memory      = var.k3s_agent_memory
  agent       = 1

  # cloud-init
  cicustom  = var.cicustom
  ciuser    = "root"
  sshkeys   = data.hcp_vault_secrets_app.k3s_homelab.secrets.ssh_keys
  ciupgrade = true
  ipconfig0 = "ip=dhcp"

  disks {
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          storage    = "local-lvm"
          size       = var.k3s_agent_storage
          emulatessd = var.emulatessd
          discard    = var.discard
        }
      }
    }
  }
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
    tag    = var.tag
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.yml.tftpl", {
    server_ips = proxmox_vm_qemu.k3s_server_vm[*].default_ipv4_address
    agent_ips  = proxmox_vm_qemu.k3s_agent_vm[*].default_ipv4_address
  })
  filename        = "${path.module}/../k3s-ansible/inventory.yml"
  file_permission = "0644"
}

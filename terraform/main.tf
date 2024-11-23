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
  sshkeys   = var.sshkeys
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
    bridge = "vmbr0"
    model  = "virtio"
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
  sshkeys   = var.sshkeys
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
    bridge = "vmbr0"
    model  = "virtio"
  }
}

variable "pm_target_node" {
  type = string
}

variable "pm_vm_template" {
  type = string
}

variable "pm_vmid_start" {
  type = number
}

variable "pm_tls_insecure" {
  type = bool
}

variable "pm_parallel" {
  type = number
}

variable "cicustom" {
  type = string
}

variable "k3s_server_num" {
  type = number
}

variable "k3s_server_cores" {
  type = number
}

variable "k3s_server_memory" {
  type = number
}

variable "k3s_server_storage" {
  type = string
}

variable "k3s_agent_num" {
  type = number
}

variable "k3s_agent_cores" {
  type = number
}

variable "k3s_agent_memory" {
  type = number
}

variable "k3s_agent_storage" {
  type = string
}

variable "emulatessd" {
  type = bool
}

variable "discard" {
  type = bool
}

variable "tag" {
  type = number
}

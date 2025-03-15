terraform {
  required_version = "~> 1.11.2"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.104.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73.1"
    }
  }
  cloud { # remote state with HCP Terraform
    organization = "dbreyfogle"
    workspaces {
      name = "k3s-homelab"
    }
  }
}

provider "hcp" {} # secret management with HCP Vault Secrets

data "hcp_vault_secrets_app" "k3s_homelab" {
  app_name = "k3s-homelab"
}

provider "proxmox" {
  endpoint  = data.hcp_vault_secrets_app.k3s_homelab.secrets.pm_endpoint
  api_token = data.hcp_vault_secrets_app.k3s_homelab.secrets.pm_api_token
  insecure  = false
  ssh {
    agent       = true
    username    = "terraform"
    private_key = data.hcp_vault_secrets_app.k3s_homelab.secrets.pm_ssh_private_key
  }
}

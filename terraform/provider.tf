terraform {
  required_version = "~> 1.10.0"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.102.0"
    }
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
  cloud {
    # HCP Terraform for state file syncing
    # configured with environment variables
  }
}

provider "hcp" {} # secrets stored in HCP Vault Secrets

data "hcp_vault_secrets_app" "k3s_homelab" {
  app_name = "k3s-homelab"
}

provider "proxmox" {
  pm_api_url          = data.hcp_vault_secrets_app.k3s_homelab.secrets.pm_api_url
  pm_api_token_id     = data.hcp_vault_secrets_app.k3s_homelab.secrets.pm_api_token_id
  pm_api_token_secret = data.hcp_vault_secrets_app.k3s_homelab.secrets.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
  pm_parallel         = var.pm_parallel
}

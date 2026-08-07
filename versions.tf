terraform {
  required_version = ">= 1.9.0"
  required_providers {
    vyos = {
      source  = "registry.terraform.io/echowings/vyos-rolling"
      version = "0.22.202608053"

    }
    proxmox = {
      source  = "local/mechanic/proxmox"
      version = "0.108.0"
    }
  }
}

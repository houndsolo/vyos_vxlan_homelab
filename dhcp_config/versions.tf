terraform {
  required_providers {
    proxmox = {
      source = "local/mechanic/proxmox"
      version = "0.109.0"
    }
    vyos = {
      source = "registry.terraform.io/echowings/vyos-rolling"
      version = "0.21.202507150"
    }
  }
}


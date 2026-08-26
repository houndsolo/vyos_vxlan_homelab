terraform {
  required_version = ">= 1.9.0"
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.99.1"
    }
    vyos = {
      source  = "registry.terraform.io/houndsolo/vyos-rolling"
      version = "0.22.202608250"
    }
    proxmox = {
      source  = "local/mechanic/proxmox"
      version = "0.108.0"
    }
  }
}

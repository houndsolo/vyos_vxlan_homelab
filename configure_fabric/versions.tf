terraform {
  required_providers {
    routeros = {
      source  = "terraform-routeros/routeros"
      version = "1.99.1"
    }
    vyos = {
      source  = "registry.terraform.io/houndsolo/vyos-rolling"
      version = "0.22.202608250"
    }
  }
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.30.0"
    }
  }
}

provider "digitalocean" {
  token = var.apitoken
}

resource "digitalocean_project" "main" {
  name        = var.identifier
  description = "A project createated from carburator"
  purpose     = "Managed project containing carburator nodes"
  environment = "Production"
}

resource "digitalocean_ssh_key" "root_ssh" {
  name       = var.keyname
  public_key = file("${var.pubkey}")
}

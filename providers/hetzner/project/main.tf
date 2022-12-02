terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.36.0"
    }
    template = {
      version = "~> 2.2.0"
    }
    local = {
      version = "~> 2.0.0"
    }
  }
}

provider "hcloud" {
  token = var.apitoken
}

# Upload project root user's public SSH key
resource "hcloud_ssh_key" "project_ssh" {
  name       = var.keyname
  public_key = file("${var.pubkey}")
}

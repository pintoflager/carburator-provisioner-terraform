terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.34.1"
    }
    template = {
      version = "~> 2.2.0"
    }
    local = {
      version = "~> 2.0.0"
    }
  }
}

###
# Say hello.
#
provider "hcloud" {
  token = var.hcloud_token
}

###
# Volumes.
#
resource "hcloud_volume" "volumes" {
  count      = length(var.volumes)
  name       = "${var.volumes[count.index].name}"
  server_id  = var.volumes[count.index].server_id
  size       = var.volumes[count.index].size
  format     = var.volumes[count.index].format
}

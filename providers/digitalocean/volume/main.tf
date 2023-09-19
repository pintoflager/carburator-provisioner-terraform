terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.30.0"
    }
  }
}

###
# Say hello.
#
provider "digitalocean" {
  token = var.digitalocean_token
}

###
# Volumes.
#
resource "digitalocean_volume" "volumes" {
  count      = length(var.volumes)
  name       = "${var.volumes[count.index].name}"
  server_id  = var.volumes[count.index].server_id
  size       = var.volumes[count.index].size
  format     = var.volumes[count.index].format
}

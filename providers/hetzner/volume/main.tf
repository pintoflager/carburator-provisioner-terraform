terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.38.2"
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
  for_each   = local.volumes
  name       = each.key
  size       = var.volume_size
  server_id  = local.provisioned_nodes[each.value]
  automount  = true
  format     = var.volume_filesystem
}

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
  for_each   = local.vol_nodes
  name       = each.key
  size       = each.value.size
  server_id  = local.provisioned_nodes[each.value.node].id
  automount  = true
  format     = each.value.fs
  labels = {
    "identifier": each.value.identifier
    "node" : each.value.node
    "cluster": local.provisioned_nodes[each.value.node].cluster
  }
}

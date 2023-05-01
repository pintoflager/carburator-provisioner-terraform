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
# Server placement.
#
resource "hcloud_placement_group" "server_placement" {
  for_each = local.clusters
  name     = each.value
  type     = "spread"
}

###
# Servers.
#
resource "hcloud_server" "servers" {
  for_each    = local.nodes
  name        = each.key
  image       = each.value.os.name
  server_type = each.value.plan.name
  location    = each.value.location.name
  public_net {
    ipv4_enabled = each.value.toggles.ipv4
    ipv6_enabled = each.value.toggles.ipv6
  }
  ssh_keys = [var.ssh_id]
  placement_group_id = hcloud_placement_group.server_placement[each.value.cluster.name].id
  labels = {
    "uuid" : each.value.ownership.ref
    "cluster": each.value.cluster.name
  }
}

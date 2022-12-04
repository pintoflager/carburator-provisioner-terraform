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

###
# Say hello.
#
provider "hcloud" {
  token = var.hcloud_token
}

###
# Server placement.
#
resource "hcloud_placement_group" "__server_placement" {
  name = "${var.node_group}-placement"
  type = "spread"
}

###
# Servers.
#
resource "hcloud_server" "servers" {
  count       = length(var.nodes)
  name        = "${var.nodes[count.index].hostname}"
  image       = "${var.nodes[count.index].os.name}"
  server_type = "${var.nodes[count.index].plan.name}"
  location    = "${var.nodes[count.index].location.name}"
  public_net {
    ipv4_enabled = var.nodes[count.index].connectivity.ipv4
    ipv6_enabled = var.nodes[count.index].connectivity.ipv6
  }
  ssh_keys = [var.ssh_id]
  placement_group_id = hcloud_placement_group.__server_placement.id
  labels = {
    "uuid" : "${var.nodes[count.index].uuid}"
  }
}

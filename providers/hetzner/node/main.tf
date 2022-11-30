terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.34.3"
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
  name = "${var.input.node_group}-placement"
  type = "spread"
}

###
# Servers.
#
resource "hcloud_server" "servers" {
  count       = length(var.input.nodes)
  name        = "${var.input.nodes[count.index].hostname}"
  image       = "${var.input.nodes[count.index].os.name}"
  server_type = "${var.input.nodes[count.index].plan.name}"
  location    = "${var.input.nodes[count.index].location.name}"
  public_net {
    ipv4_enabled = var.input.nodes[count.index].connectivity.public_ipv4
    ipv6_enabled = var.input.nodes[count.index].connectivity.public_ipv6
  }
  ssh_keys = [var.ssh_id]
  placement_group_id = hcloud_placement_group.__server_placement.id
}

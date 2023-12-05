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

resource "digitalocean_tag" "uuid" {
  for_each    = local.nodes
  name        = each.value.uuid
}

resource "digitalocean_tag" "cluster" {
  for_each    = local.clusters
  name        = each.value
}

###
# Servers.
#
resource "digitalocean_droplet" "servers" {
  for_each    = local.nodes
  image       = each.value.os.name
  name        = each.key
  region      = each.value.location.name
  size        = each.value.plan.name
  ipv6        = each.value.toggles.ipv6
  ssh_keys    = [var.ssh_id]
  tags        = [
    digitalocean_tag.uuid[each.value.uuid].id,
    digitalocean_tag.cluster[each.value.cluster].id
  ]
}

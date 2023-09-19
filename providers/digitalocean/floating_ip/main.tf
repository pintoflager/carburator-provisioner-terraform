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
# Floating IPs.
#
# resource "digitalocean_floating_ip" "floating_ip_v4" {
#   count      = var.floating_ip_v4 ? 1 : 0
#   type       = "ipv4"
#   name       = "${var.floating_ip_name}-v4"
#   server_id  = local.provisioned_nodes[local.labels_v4["primary"]]
#   labels     = local.labels_v4
# }

# resource "digitalocean_floating_ip" "floating_ip_v6" {
#   count      = var.floating_ip_v6 ? 1 : 0
#   type       = "ipv6"
#   name       = "${var.floating_ip_name}-v6"
#   server_id  = local.provisioned_nodes[local.labels_v6["primary"]]
#   labels     = local.labels_v6
# }

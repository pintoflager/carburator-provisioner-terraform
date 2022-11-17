###
# Server details.
# Outputs an JSON array with server nodes as objects.
#
output "servers" {
  description = "Server details for ansible."
  value = [
    for i, v in hcloud_server.servers: ({
      cloud_provider      = "hetzner"
      name                = v.name
      id                  = v.id
      image               = v.image
      type                = v.server_type
      ipv4_enabled        = var.servers[i].ipv4_enabled
      ipv4                = v.ipv4_address
      ipv6_enabled        = var.servers[i].ipv6_enabled
      ipv6                = v.ipv6_address
      ipv6_block          = v.ipv6_network
      location            = v.location
      labels              = v.labels
    })
  ]
}

output "server_placement" {
  description = "Placement group for the cluster servers"
  value       = {
    name   = hcloud_placement_group.__server_placement.name
    id     = hcloud_placement_group.__server_placement.id
  }
}

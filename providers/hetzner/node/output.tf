###
# Principal output for nodes.
#
output "node" {
  description = "Server details for ansible."
  value = [
    for i, v in hcloud_server.servers: ({
      cloud_provider      = "hetzner"
      name                = v.name
      id                  = v.id
      image               = v.image
      type                = v.server_type
      ipv4                = v.ipv4_address
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

###
# Principal output for nodes.
#
output "node" {
  description = "Server nodes from clusters"
  value = [
    for i, v in hcloud_server.servers: ({
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
  description = "Placement groups for each cluster"
  value       = [
    for i, v in hcloud_placement_group.server_placement: ({
      name = v.name
      id   = v.id
      type = v.type
    })
  ]
}

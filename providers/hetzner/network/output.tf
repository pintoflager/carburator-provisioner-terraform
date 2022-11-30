###
# Private network output.
#
output "network" {
  description = "Private network connecting nodes"
  value       = {
    name        = hcloud_network.private_networks.name
    id          = hcloud_network.private_networks.id
    ip_range    = hcloud_network.private_networks.ip_range
    subnet      = {
      id     = hcloud_network_subnet.private_networks_subnet.id
      range  = hcloud_network_subnet.private_networks_subnet.ip_range
      zone   = hcloud_network_subnet.private_networks_subnet.network_zone
    }
  }
}

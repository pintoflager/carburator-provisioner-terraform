###
# Private network output.
#
output "network" {
  description = "Private network connecting nodes"
  value       = [
    for i, v in digitalocean_vpc.private_networks: ({
      id = v.id
    })
  ]
}

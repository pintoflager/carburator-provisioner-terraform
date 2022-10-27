###
# Virtual IP details.
# Outputs an JSON array with virtual IP addresses as objects.
#

output "virtual_ip" {
  description = "Main entrypoint to the cluster."
  value = {
    "ipv4" = [
      for i, v in hcloud_floating_ip.virtual_ipv4: ({
        name   = length(v) > 0 ? v.name : null
        id     = length(v) > 0 ? v.id : null
        ip     = length(v) > 0 ? v.ip_address : null
      })
    ],
    "ipv6" = [
      for i, v in hcloud_floating_ip.virtual_ipv6: ({
        name   = length(v) > 0 ? v.name : null
        id     = length(v) > 0 ? v.id : null
        ip     = length(v) > 0 ? v.ip_address : null
      })
    ]
  }
}

###
# Virtual IP details.
# Outputs an JSON array with virtual IP addresses as objects.
#

output "floating_ip" {
  description = "Floating IP address, easily transfered into another node."
  value = {
    # "ipv4" = one(digitalocean_floating_ip.floating_ip_v4),
    # "ipv6" = one(digitalocean_floating_ip.floating_ip_v6)
  }
}

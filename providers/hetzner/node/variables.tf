# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

# Has to be added as TF_VAR before running init / apply
variable "ssh_id" {
  type = string
  default = ""
}

variable "node_group" {
  type = string
}

variable "nodes" {
  type = list(
    object({
      hostname = string
      uuid = string
      os = object({
        name = string
      })
      plan = object({
        name = string
      })
      location = object({
        name = string
      })
      connectivity = object({
        ipv4 = bool
        ipv6 = bool
      })
    })  
  )
}

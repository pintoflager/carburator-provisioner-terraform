# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "floating_ip_name" {
  type = string
}

variable "floating_ip_v4" {
  type = bool
}

variable "floating_ip_v6" {
  type = bool
}

variable "nodes" {
  type = list(
    object({
      hostname = string
      ownership = object({
        ref = string
      })
      toggles = object({
        ipv4 = bool
        ipv6 = bool
      })
    })  
  )
}

# Output from node creation, needed for node ID's
variable "nodes_output" {
  type = list(
    object({
      name     = string
      id       = string
      labels   = object({
        uuid     = string
      })
    })
  )
}

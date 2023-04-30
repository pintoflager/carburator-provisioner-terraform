# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "net_range" {
  type = string
}

variable "net_type" {
  type = string
}

variable "net_nodes" {
  type = list(
    object({
      cluster = object({
        name = string
      })
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
      toggles = object({
        ipv4 = bool
        ipv6 = bool
      })
    })  
  )
}

variable "nodes_output" {
  type = list(
    object({
      name     = string
      id       = string
    })
  )
}

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

# Nodes chosen to be added to network, carburator produced list.
variable "net_nodes" {
  type = list(
    object({
      cluster = string
      location = object({
        name = string
      })
      ownership = object({
        ref = string
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

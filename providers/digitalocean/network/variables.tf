# Has to be added as TF_VAR before running init / apply
variable "digitalocean_token" {
  type = string
  description = "The token that will be used to connect to the Digital Ocean Cloud API."
  sensitive = true
}

variable "net_range" {
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
    })  
  )
}

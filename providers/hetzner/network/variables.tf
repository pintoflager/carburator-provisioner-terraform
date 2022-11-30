# Has to be added as TF_VAR before running init / apply
variable "hcloud_token" {
  type = string
  description = "The token that will be used to connect to the Hetzner Cloud API."
  sensitive = true
}

variable "network" {
  type = list(
    object({
      name       = string
      range      = string
      zone       = string
      type       = string
      nodes      = list(string)
    })
  )
}

variable "nodes" {
  type = object({
    value = list(
      object({
        name     = string
        id       = string
      })
    )
  })
}

# Has to be added as TF_VAR before running init / apply
variable "apitoken" {
  type = string
  description = "The token that will be used to connect to the Digital Ocean Cloud API."
  sensitive = true
}

variable "identifier" {
  type = string
  description = "Project identifier"
}

variable "keyname" {
  type = string
  description = "Project root SSH key name"
}

variable "pubkey" {
  type = string
  description = "Path to project roots' public SSH key"
}

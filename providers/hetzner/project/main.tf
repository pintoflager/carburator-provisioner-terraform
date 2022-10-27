terraform {
  required_providers = var.providers
}

provider "hcloud" {
  token = var.api_token
}

###
# Security.
#

# Upload copy of server user SSH key
resource "hcloud_ssh_key" "project_ssh" {
  name       = var.sshkey["name"]
  public_key = file("${var.sshkey["path"]}.pub")
}

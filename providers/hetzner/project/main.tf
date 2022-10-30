terraform {
  required_providers = var.providers
}

provider "hcloud" {
  token = var.apitoken
}

# Upload project root user's public SSH key
resource "hcloud_ssh_key" "project_ssh" {
  name       = var.keyname
  public_key = file("${var.pubkey}")
}

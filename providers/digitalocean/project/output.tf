###
# Principal output for project.
#
output "project" {
  description = "Project ID from the service provider"
  value    = {
    id            = digitalocean_project.main.id
    owner_id      = digitalocean_project.main.owner_id
    sshkey_name   = digitalocean_ssh_key.root_ssh.name
    sshkey_id     = digitalocean_ssh_key.root_ssh.id
  }
}

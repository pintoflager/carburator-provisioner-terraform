###
# Principal output for project.
#
output "project" {
  description = "Project root user SSH key"
  value    = {
    sshkey_name   = hcloud_ssh_key.root_ssh.name
    sshkey_id     = hcloud_ssh_key.root_ssh.id
  }
}

output "ssh_key" {
  description = "Uploaded project user public SSH key."
  value       = {
    name   = hcloud_ssh_key.project_ssh.name
    id     = hcloud_ssh_key.project_ssh.id
  }
}

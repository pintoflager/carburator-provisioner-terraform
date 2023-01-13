###
# Output from repository.
#
output "repository" {
  description = "Repository creation output"
  value    = {
    name          = github_repository.repository.full_name
    url           = github_repository.repository.html_url
    ssh_url       = github_repository.repository.ssh_clone_url
    https_url     = github_repository.repository.http_clone_url
    id            = github_repository.repository.repo_id
  }
}

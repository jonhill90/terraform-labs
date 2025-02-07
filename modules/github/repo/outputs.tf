output "repo_url" {
  description = "GitHub repository URL"
  value       = github_repository.repo.html_url
}

output "ssh_clone_url" {
  description = "SSH URL for cloning the repository"
  value       = github_repository.repo.ssh_clone_url
}
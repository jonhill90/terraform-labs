resource "null_resource" "push_twingate_image" {
  provisioner "local-exec" {
    command     = <<EOT
      az acr login --name ${var.registry_login_server}
      docker pull --platform=linux/amd64 twingate/connector:latest
      docker tag twingate/connector:latest ${var.registry_login_server}/${var.image_name}:${var.image_tag}
      docker push ${var.registry_login_server}/${var.image_name}:${var.image_tag}
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}
resource "null_resource" "go_code_keeper" {
  triggers = {
    code_hash  = md5(join("", [
      filemd5("${path.module}/main.go"),
      filemd5("${path.module}/pkg/config.go"),
      filemd5("${path.module}/pkg/push_event_handler.go")
    ]))
    dockerfile = filemd5("${path.module}/Dockerfile")
  }
}

resource "docker_image" "proxy" {
  name = "${var.registry_url}/avm-github-app"
  build {
    context = path.module
    tag     = ["${var.registry_url}/avm-github-app:${var.image_tag}"]
  }
  triggers = {
    code_hash  = filemd5("${path.module}/main.go")
    dockerfile = filemd5("${path.module}/Dockerfile")
  }

  lifecycle {
    replace_triggered_by = [null_resource.go_code_keeper]
  }
}

resource "docker_registry_image" "proxy" {
  name          = docker_image.proxy.name
  keep_remotely = true

  lifecycle {
    replace_triggered_by = [null_resource.go_code_keeper]
  }
}
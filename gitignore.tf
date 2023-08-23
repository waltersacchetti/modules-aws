resource "local_file" "crete_gitignore" {
  filename = "${path.root}/.gitignore"
  content  = templatefile("${path.module}/templates/gitignore.tftpl", {})
}
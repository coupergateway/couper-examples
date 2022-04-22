server {
  files {
    document_root = "/htdocs"
  }

  spa {
    bootstrap_file = "/htdocs/index.html"
    paths = ["/", "/app"]
  }
}

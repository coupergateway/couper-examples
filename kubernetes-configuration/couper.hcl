server {
  # we will mount this config on another dir, but want serve an index file
  files {
    document_root = "/htdocs"
  }

  endpoint "/hello" {
    response {
      body = "Hello! I am ${env.MY_POD_NAME}"
    }
  }
}

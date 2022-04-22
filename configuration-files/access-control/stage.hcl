server {
  access_control = ["my-ba"]
}

definitions {
  basic_auth "my-ba" {
    password = "test"
  }
}

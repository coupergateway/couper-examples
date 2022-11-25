server {
  access_control = ["production-ba"]
}

definitions {
  basic_auth "production-ba" {
    htpasswd_file = ".htpasswd"
  }
}

environment "test" {
  server {
    access_control = ["credentials"]
  }

  definitions {
    basic_auth "credentials" {
      user     = "user"
      password = "p4ssw0rd"
    }
  }
}

server "secured-api" {
  access_control = ["JWTToken"]
  api {
    endpoint "/private/**" {
      path = "/**"
      backend {
        origin = "https://httpbin.org/"
      }
    }
  }

}

definitions {
    jwt "JWTToken" {
        header = "Authorization"
        signature_algorithm = "RS256"
        key = <<EOF
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDGSd+sSTss2uOuVJKpumpFAaml
t1CWLMTAZNAabF71Ur0P6u833RhAIjXDSA/QeVitzvqvCZpNtbOJVegaREqLMJqv
FOUkFdLNRP3f9XjYFFvubo09tcjX6oGEREKDqLG2MfZ2Z8LVzuJc6SwZMgVFk/63
rdAOci3W9u3zOSGj4QIDAQAB
-----END PUBLIC KEY-----
        EOF
        // alternative: read from file
        //key_file = "pub.pem"
        // … or from env
        // key = env.JWT_PUB_KEY
        required_claims = ["iss"]
        claims = {
            sub = "some_user"
        }
    }
}

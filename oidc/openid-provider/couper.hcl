server "oauth-as" {
  files {
    document_root = "./htdocs"
  }
  api {
    endpoint "/auth" {
      response {
        status = 303
        headers = {
          cache-control = "no-cache, no-store"
          # fake: use nonce as code to use it later at token endpoint
          location = "${request.query.redirect_uri[0]}?code=${default(request.query.nonce[0], "asdf")}${request.query.state != null ? "&state=${url_encode(request.query.state[0])}" : ""}"
        }
      }
    }
    endpoint "/token" {
      response {
        headers = {
          cache-control = "no-cache, no-store"
        }
        json_body = {
          access_token = jwt_sign("token", {
            aud = "http://host.docker.internal:8081"
            cid = request.headers.authorization != null ? split(":", base64_decode(substr(request.headers.authorization, 6, -1)))[0] : request.form_body.client_id[0]
            sub = "qibneqin1p41v9"
          })
          id_token = jwt_sign("token", {
            aud = request.headers.authorization != null ? split(":", base64_decode(substr(request.headers.authorization, 6, -1)))[0] : request.form_body.client_id[0]
            sub = "qibneqin1p41v9"
            name = "John Doe"
            given_name = "John"
            family_name = "Doe"
            preferred_username = "john.doe"
            # fake: set code as nonce, if not default code value
            nonce = request.form_body.code[0] == "asdf" ? null : request.form_body.code[0]
          })
          token_type = "Bearer"
          expires_in = 3600
        }
      }
    }
    endpoint "/userinfo" {
      access_control = ["token"]
      response {
        headers = {
          cache-control = "no-cache, no-store"
        }
        json_body = {
          sub = request.context.token.sub
        }
      }
    }
  }
}

definitions {
  jwt_signing_profile "token" {
    signature_algorithm = "RS256"
    ttl = "1h"
    key_file = "pkcs8.key"
    claims = {
      iss = "http://host.docker.internal:8081"
      iat = unixtime()
    }
    headers = {
      kid = "rs256"
    }
  }

  jwt "token" {
    jwks_url = "http://host.docker.internal:8081/jwks.json"
    header = "authorization"
    required_claims = ["iat", "exp"]
    claims = {
      iss = "http://host.docker.internal:8081"
      aud = "http://host.docker.internal:8081"
    }
  }
}

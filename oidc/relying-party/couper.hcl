server {
  files {
    document_root = "htdocs"
  }

  endpoint "/oidc/login" {
    response {
      headers = {
        cache-control = "no-cache,no-store"
        set-cookie = "authvv=${oauth2_verifier()};HttpOnly;Secure;Path=/oidc/redir"
      }
      json_body = {
        url = "${oauth2_authorization_url("MyOIDC")}&state=${url_encode(relative_url(request.form_body.url[0]))}"
      }
    }
  }

  endpoint "/oidc/redir" {
    access_control = ["MyOIDC"]
    response {
      status = 303
      headers = {
        set-cookie = [
          "UserToken=${jwt_sign("UserToken", { for k in ["sub", "name", "given_name", "family_name", "preferred_username"]: k => request.context.MyOIDC.id_token_claims[k] })};HttpOnly;Secure;Path=/api",
          "authvv=;HttpOnly;Secure;Path=/oidc/redir;Max-Age=0"
        ]
        location = relative_url(request.query.state[0])
      }
    }
  }

  api {
    base_path = "/api"
    access_control = ["UserToken"]

    endpoint "/userinfo" {
      response {
        json_body = request.context.UserToken
      }
    }
  }
}
definitions {
  jwt "UserToken" {
    signature_algorithm = "HS256"
    key = "Th3$e(rEt"
    cookie = "UserToken"
    signing_ttl = "1h"
  }

  oidc "MyOIDC" {
    configuration_url = "http://testop:8080/.well-known/openid-configuration"
    client_id = env.RP_CLIENT_ID
    client_secret = env.RP_CLIENT_SECRET
    redirect_uri = "/oidc/redir"
    verifier_value = request.cookies.authvv
  }
}
defaults {
  environment_variables = {
    RP_CLIENT_ID = "foo"
    RP_CLIENT_SECRET = "bar"
  }
}

server "saml" {
  files {
    document_root = "htdocs"
  }

  endpoint "/saml/login" {
    response {
      headers = {
        cache-control = "no-cache,no-store"
      }
      json_body = {
        url = saml_sso_url("SSO")
      }
    }
  }

  endpoint "/saml/acs" {
    access_control = ["SSO"]
    response {
      status = 303
      headers = {
        set-cookie = "UserToken=${jwt_sign("UserToken", {
          sub = request.context.SSO.sub
          mail = request.context.SSO.attributes.email
          groups = request.context.SSO.attributes.eduPersonAffiliation
        })};HttpOnly;Secure;Path=/api"
        location = "/"
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

  saml "SSO" {
    idp_metadata_file = "idp-metadata.xml"
    sp_entity_id = env.SP_ENTITY_ID
    sp_acs_url = "http://localhost:8080/saml/acs"
    array_attributes = ["eduPersonAffiliation"]
  }
}

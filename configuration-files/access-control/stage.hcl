server {
  access_control = ["stage-ba"]
}

definitions {
  basic_auth "stage-ba" {
    password = env.STAGE_BA_PASSWD
  }
}

defaults {
  environment_variables = {
    STAGE_BA_PASSWD = "test"
  }
}

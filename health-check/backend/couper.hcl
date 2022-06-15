server {
  api {
    endpoint "/" {
      response {
        # fail every 15 seconds for a period of 15 seconds
        status =  (unixtime() % 30) < 15 ? 200 : 500
      }
    }
  }
}

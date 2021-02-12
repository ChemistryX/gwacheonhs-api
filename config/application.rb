Jets.application.configure do
  config.project_name = "gwacheonhs-api"
  config.mode = "api"

  config.prewarm.enable = true
  config.prewarm.rate = "6 hours"

  config.controllers.default_protect_from_forgery = false
end

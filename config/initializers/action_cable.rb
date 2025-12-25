# frozen_string_literal: true

# Action Cable configuration for high concurrency
Rails.application.configure do
  # Mount Action Cable at /cable
  config.action_cable.mount_path = "/cable"
  
  if Rails.env.production?
    # Allow connections from production domains
    config.action_cable.allowed_request_origins = [
      "https://flikk.co.in",
      "https://www.flikk.co.in",
      "https://flikk-app.fly.dev",
      %r{https://.*\.flikk\.co\.in}
    ]
    
    # Disable request forgery protection for WebSockets (they use their own auth)
    config.action_cable.disable_request_forgery_protection = true
  else
    # In development, allow connections from localhost
    config.action_cable.allowed_request_origins = [
      "http://localhost:3000",
      "http://127.0.0.1:3000",
      %r{http://.*}
    ]
  end
end

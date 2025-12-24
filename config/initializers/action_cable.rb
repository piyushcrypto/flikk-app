# frozen_string_literal: true

# Action Cable configuration for high concurrency
Rails.application.configure do
  # Allow connections from any origin in production (configure specific domains as needed)
  if Rails.env.production?
    config.action_cable.allowed_request_origins = [
      "https://flikk.co.in",
      "https://www.flikk.co.in",
      "https://flikk-app.fly.dev",
      %r{https://.*\.flikk\.co\.in}
    ]
    
    # Mount Action Cable at /cable
    config.action_cable.mount_path = "/cable"
    
    # Disable request forgery protection for WebSockets (they use their own auth)
    config.action_cable.disable_request_forgery_protection = true
  end
end


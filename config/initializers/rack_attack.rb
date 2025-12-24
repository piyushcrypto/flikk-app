# frozen_string_literal: true

# Rate limiting configuration for high traffic scalability
class Rack::Attack
  ### Configure Cache ###
  # Use Redis in production, memory store in development
  if Rails.env.production? && ENV["REDIS_URL"].present?
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])
  else
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  ### Throttle Strategies ###

  # Throttle all requests by IP (60 requests per minute)
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip unless req.path.start_with?("/assets", "/packs")
  end

  # Throttle message creation (prevent spam) - 30 messages per minute per user
  throttle("messages/user", limit: 30, period: 1.minute) do |req|
    if req.path =~ %r{/conversations/\d+/messages} && req.post?
      # Use session or IP for rate limiting
      req.env["warden"]&.user&.id || req.ip
    end
  end

  # Throttle login attempts by IP - 5 per minute
  throttle("login/ip", limit: 5, period: 1.minute) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email - 5 per 20 seconds
  throttle("login/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Normalize email
      req.params.dig("user", "email")&.to_s&.downcase&.strip
    end
  end

  # Throttle password reset requests - 5 per hour
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    if req.path == "/users/password" && req.post?
      req.ip
    end
  end

  # Throttle API calls for conversations - 120 per minute
  throttle("conversations/user", limit: 120, period: 1.minute) do |req|
    if req.path.start_with?("/conversations")
      req.env["warden"]&.user&.id || req.ip
    end
  end

  # Throttle go_live/go_offline - 10 per minute
  throttle("live_status/user", limit: 10, period: 1.minute) do |req|
    if req.path =~ %r{/creator/dashboard/(go_live|go_offline)}
      req.env["warden"]&.user&.id || req.ip
    end
  end

  ### Custom Responses ###
  
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{ error: "Rate limit exceeded. Try again in #{retry_after} seconds." }.to_json]
    ]
  end

  ### Safelist ###
  
  # Always allow requests from localhost in development
  safelist("allow-localhost") do |req|
    Rails.env.development? && (req.ip == "127.0.0.1" || req.ip == "::1")
  end
end


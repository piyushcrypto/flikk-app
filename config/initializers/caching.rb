# frozen_string_literal: true

# Caching configuration for high traffic scalability
Rails.application.configure do
  if Rails.env.production?
    # Use Redis for caching in production
    if ENV["REDIS_URL"].present?
      config.cache_store = :redis_cache_store, {
        url: ENV["REDIS_URL"],
        namespace: "flikk_cache",
        expires_in: 1.hour,
        race_condition_ttl: 10.seconds,
        error_handler: -> (method:, returning:, exception:) {
          Rails.logger.error("Redis cache error: #{exception.message}")
          Sentry.capture_exception(exception) if defined?(Sentry)
        }
      }
    else
      # Fallback to memory store if Redis is not available
      config.cache_store = :memory_store, { size: 64.megabytes }
    end
  else
    # Use memory store in development/test
    config.cache_store = :memory_store, { size: 64.megabytes }
  end
end


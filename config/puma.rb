# This configuration file will be evaluated by Puma. The top-level methods that
# are invoked here are part of Puma's configuration DSL. For more information
# about methods provided by the DSL, see https://puma.io/puma/Puma/DSL.html.

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

rails_env = ENV.fetch("RAILS_ENV") { "development" }

if rails_env == "production"
  # For high concurrency with 2000+ users:
  # - Use 2-4 workers per CPU core
  # - Each worker can handle max_threads concurrent requests
  # - Total capacity = workers * max_threads
  # 
  # With 2 workers and 5 threads = 10 concurrent requests
  # For 2000 concurrent users, many will be on WebSockets (Action Cable)
  # which don't consume Puma threads after initial connection
  worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 2 })
  workers worker_count
  
  # Preload the application for faster worker spawning and memory savings (Copy-on-Write)
  preload_app!
  
  # Allow workers to reload their application
  on_worker_boot do
    ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
  end
end

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
worker_timeout 3600 if rails_env == "development"

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
# Bind to 0.0.0.0 in production for container/cloud environments
if rails_env == "production"
  bind "tcp://0.0.0.0:#{ENV.fetch('PORT') { 3000 }}"
else
  port ENV.fetch("PORT") { 3000 }
end

# Specifies the `environment` that Puma will run in.
environment rails_env

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Reduce memory usage with jemalloc (must be installed in Dockerfile)
before_fork do
  # Close parent's DB connections before forking
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

# Log basic info about Puma startup
lowlevel_error_handler do |e, env, status|
  puts "[Puma Error] #{e.class}: #{e.message}"
  puts e.backtrace.first(10).join("\n")
  [status, {}, ["Internal Server Error"]]
end

// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import consumer from "channels"
import "notifications"
import "turbo_cleanup"

// Make consumer available globally for use in inline scripts
window.App = window.App || {}
window.App.cable = consumer

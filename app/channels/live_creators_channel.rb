# Channel for broadcasting live creator status updates
# This allows fans to see real-time updates when creators go live/offline
class LiveCreatorsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "live_creators"
    logger.info "User #{current_user.id} subscribed to live creators channel"
  end

  def unsubscribed
    stop_all_streams
  end
end


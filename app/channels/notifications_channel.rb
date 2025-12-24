class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{current_user.id}"
    logger.info "User #{current_user.id} subscribed to notifications"
    
    # Send initial unread count on subscription
    transmit({
      type: 'initial_state',
      unread_count: Conversation.total_unread_for_user(current_user)
    })
  end

  def unsubscribed
    stop_all_streams
    logger.info "User #{current_user.id} unsubscribed from notifications"
  end

  def get_unread_count
    transmit({
      type: 'unread_count',
      count: Conversation.total_unread_for_user(current_user)
    })
  rescue => e
    logger.error "Error getting unread count: #{e.message}"
  end
end

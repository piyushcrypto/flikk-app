class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = find_conversation
    return reject unless conversation
    
    # Only allow participants to subscribe
    unless conversation.participant?(current_user)
      logger.warn "Unauthorized subscription attempt for conversation #{params[:conversation_id]} by user #{current_user.id}"
      return reject
    end
    
    stream_from "conversation_#{conversation.id}"
    logger.info "User #{current_user.id} subscribed to conversation #{conversation.id}"
  end

  def unsubscribed
    stop_all_streams
    logger.info "User #{current_user.id} unsubscribed from conversation channel"
  end

  def mark_as_read(data)
    conversation = find_conversation(data['conversation_id'])
    return unless conversation&.participant?(current_user)
    
    conversation.mark_as_read_for!(current_user)
  rescue => e
    logger.error "Error marking messages as read: #{e.message}"
  end

  def typing(data)
    conversation = find_conversation(data['conversation_id'])
    return unless conversation&.participant?(current_user)
    
    # Broadcast typing indicator to the conversation
    # This is a lightweight broadcast that doesn't hit the database
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: 'typing',
        user_id: current_user.id,
        user_name: current_user.name,
        is_typing: data['is_typing']
      }
    )
  rescue => e
    logger.error "Error broadcasting typing status: #{e.message}"
  end

  private

  def find_conversation(id = nil)
    conversation_id = id || params[:conversation_id]
    return nil unless conversation_id
    
    Conversation.find_by(id: conversation_id)
  end
end

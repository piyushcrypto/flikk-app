class ConversationChannel < ApplicationCable::Channel
  def subscribed
    @conversation = find_conversation
    return reject unless @conversation
    
    # Only allow participants to subscribe
    unless @conversation.participant?(current_user)
      logger.warn "Unauthorized subscription attempt for conversation #{params[:conversation_id]} by user #{current_user.id}"
      return reject
    end
    
    stream_from "conversation_#{@conversation.id}"
    logger.info "User #{current_user.id} subscribed to conversation #{@conversation.id}"
  end

  def unsubscribed
    stop_all_streams
    logger.info "User #{current_user.id} unsubscribed from conversation channel"
  end

  # Send message via WebSocket instead of HTTP POST
  def send_message(data)
    return unless @conversation&.participant?(current_user)
    
    content = data['content']&.strip
    return if content.blank?
    
    # Validate content length
    if content.length > 2000
      transmit({ type: 'error', message: 'Message too long (max 2000 characters)' })
      return
    end

    # Create the message
    message = @conversation.messages.create!(
      sender: current_user,
      content: content,
      message_type: data['message_type'] || 'text'
    )

    # Send confirmation back to sender
    transmit({
      type: 'message_sent',
      temp_id: data['temp_id'],
      message: serialize_message(message)
    })

    logger.info "User #{current_user.id} sent message #{message.id} in conversation #{@conversation.id}"
  rescue ActiveRecord::RecordInvalid => e
    transmit({ type: 'error', message: e.message, temp_id: data['temp_id'] })
    logger.error "Error creating message: #{e.message}"
  rescue => e
    transmit({ type: 'error', message: 'Failed to send message', temp_id: data['temp_id'] })
    logger.error "Error sending message: #{e.message}"
  end

  def mark_as_read(data)
    conversation = find_conversation(data['conversation_id'])
    return unless conversation&.participant?(current_user)
    
    conversation.mark_as_read_for!(current_user)
  rescue => e
    logger.error "Error marking messages as read: #{e.message}"
  end

  def typing(data)
    return unless @conversation&.participant?(current_user)
    
    # Broadcast typing indicator to the conversation
    # This is a lightweight broadcast that doesn't hit the database
    ActionCable.server.broadcast(
      "conversation_#{@conversation.id}",
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

  # React to a message via WebSocket
  def react(data)
    return unless @conversation&.participant?(current_user)

    message_id = data['message_id']
    emoji = data['emoji']

    return unless message_id.present? && emoji.present?
    return unless MessageReaction::ALLOWED_EMOJIS.include?(emoji)

    message = @conversation.messages.find_by(id: message_id)
    return unless message

    # Toggle reaction (add if not exists, remove if exists)
    reaction = message.reactions.find_by(user: current_user, emoji: emoji)

    if reaction
      reaction.destroy
      action = 'removed'
    else
      reaction = message.reactions.create(user: current_user, emoji: emoji)
      action = reaction.persisted? ? 'added' : nil
    end

    if action
      transmit({
        type: 'reaction_confirmed',
        message_id: message_id,
        emoji: emoji,
        action: action,
        reaction_counts: message.reaction_counts
      })
    end

    logger.info "User #{current_user.id} #{action} reaction #{emoji} on message #{message_id}"
  rescue => e
    logger.error "Error processing reaction: #{e.message}"
    transmit({ type: 'error', message: 'Failed to process reaction' })
  end

  private

  def find_conversation(id = nil)
    conversation_id = id || params[:conversation_id]
    return nil unless conversation_id
    
    Conversation.find_by(id: conversation_id)
  end

  def serialize_message(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      content: message.content,
      message_type: message.message_type,
      read_at: message.read_at,
      created_at: message.created_at.iso8601,
      is_read: message.read?
    }
  end
end

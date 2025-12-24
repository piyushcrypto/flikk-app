class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find(params[:conversation_id])
    
    # Only allow participants to subscribe
    if conversation.participant?(current_user)
      stream_from "conversation_#{conversation.id}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    stop_all_streams
  end

  def mark_as_read(data)
    conversation = Conversation.find(data['conversation_id'])
    
    if conversation.participant?(current_user)
      conversation.mark_as_read_for!(current_user)
      
      # Broadcast read status to the other participant
      other = conversation.other_participant(current_user)
      ActionCable.server.broadcast(
        "notifications_#{other.id}",
        {
          type: 'messages_read',
          conversation_id: conversation.id,
          reader_id: current_user.id
        }
      )
    end
  end

  def typing(data)
    conversation = Conversation.find(data['conversation_id'])
    
    if conversation.participant?(current_user)
      # Broadcast typing indicator to the other participant
      ActionCable.server.broadcast(
        "conversation_#{conversation.id}",
        {
          type: 'typing',
          user_id: current_user.id,
          user_name: current_user.name,
          is_typing: data['is_typing']
        }
      )
    end
  end
end


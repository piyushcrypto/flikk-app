# Broadcast message via Action Cable in background
# This keeps message creation fast and offloads broadcast to async processing
class BroadcastMessageJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.includes(:sender, :conversation).find_by(id: message_id)
    return unless message

    serialized_message = {
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

    # Broadcast to conversation channel
    ActionCable.server.broadcast(
      "conversation_#{message.conversation_id}",
      {
        type: 'new_message',
        message: serialized_message,
        conversation_id: message.conversation_id
      }
    )

    # Broadcast to recipient's notification channel
    recipient_id = message.recipient_id
    ActionCable.server.broadcast(
      "notifications_#{recipient_id}",
      {
        type: 'new_message',
        conversation_id: message.conversation_id,
        sender_name: message.sender.name,
        preview: message.content.truncate(50),
        unread_count: nil
      }
    )
  rescue => e
    Rails.logger.error("BroadcastMessageJob failed for message #{message_id}: #{e.message}")
  end
end


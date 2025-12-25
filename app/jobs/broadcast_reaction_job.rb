# Broadcast reaction updates via Action Cable
class BroadcastReactionJob < ApplicationJob
  queue_as :notifications

  def perform(message_id, action, emoji, user_id)
    message = Message.find_by(id: message_id)
    return unless message

    user = User.find_by(id: user_id)
    return unless user

    # Get updated reaction counts
    reaction_counts = MessageReaction.counts_for_message(message_id)

    # Broadcast to conversation channel
    ActionCable.server.broadcast(
      "conversation_#{message.conversation_id}",
      {
        type: 'reaction_update',
        message_id: message_id,
        action: action,
        emoji: emoji,
        user_id: user_id,
        user_name: user.name,
        reaction_counts: reaction_counts
      }
    )
  rescue => e
    Rails.logger.error("BroadcastReactionJob failed: #{e.message}")
  end
end


class Message < ApplicationRecord
  belongs_to :conversation, touch: true  # Auto-update conversation's updated_at
  belongs_to :sender, class_name: 'User'

  # Message types: 0 = text, 1 = image, 2 = tip, 3 = request
  enum :message_type, { text: 0, image: 1, tip: 2, request: 3 }, default: :text

  validates :content, presence: true, length: { maximum: 2000 }

  # Use background job for non-critical callbacks to speed up response
  after_create_commit :update_conversation_timestamp
  after_create_commit :increment_unread_count
  after_create_commit :broadcast_message_async

  scope :ordered, -> { order(created_at: :asc) }
  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(50) }

  # Check if this message is from the current user
  def from?(user)
    sender_id == user.id
  end

  # Check if message is read
  def read?
    read_at.present?
  end

  # Get the recipient of this message (cached to avoid repeated queries)
  def recipient
    @recipient ||= begin
      if sender_id == conversation.fan_id
        conversation.creator
      else
        conversation.fan
      end
    end
  end

  # Get recipient ID without loading association
  def recipient_id
    if sender_id == conversation.fan_id
      conversation.creator_id
    else
      conversation.fan_id
    end
  end

  private

  def update_conversation_timestamp
    # Use update_column to skip callbacks and validations for performance
    conversation.update_column(:last_message_at, created_at)
  end

  def increment_unread_count
    # Use increment! with touch: false to avoid unnecessary callbacks
    if sender_id == conversation.fan_id
      # Fan sent message, increment creator's unread count
      Conversation.where(id: conversation_id).update_all("unread_creator_count = unread_creator_count + 1")
    else
      # Creator sent message, increment fan's unread count
      Conversation.where(id: conversation_id).update_all("unread_fan_count = unread_fan_count + 1")
    end
  end

  def broadcast_message_async
    # Use inline broadcasting for real-time responsiveness
    # In a high-scale scenario, this could be moved to Active Job
    broadcast_message
  end

  def broadcast_message
    # Cache the serialized message to avoid repeated serialization
    serialized_message = {
      id: id,
      conversation_id: conversation_id,
      sender_id: sender_id,
      sender_name: sender.name,
      content: content,
      message_type: message_type,
      read_at: read_at,
      created_at: created_at.iso8601,
      is_read: read?
    }

    # Broadcast to conversation channel
    ActionCable.server.broadcast(
      "conversation_#{conversation_id}",
      {
        type: 'new_message',
        message: serialized_message,
        conversation_id: conversation_id
      }
    )

    # Broadcast to recipient's notification channel
    # Avoid loading recipient if we can use the ID
    ActionCable.server.broadcast(
      "notifications_#{recipient_id}",
      {
        type: 'new_message',
        conversation_id: conversation_id,
        sender_name: sender.name,
        preview: content.truncate(50),
        unread_count: nil  # Client should fetch updated count
      }
    )
  rescue => e
    # Log but don't fail the message creation if broadcast fails
    Rails.logger.error("Failed to broadcast message #{id}: #{e.message}")
  end
end

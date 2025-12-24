class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: 'User'

  # Message types: 0 = text, 1 = image, 2 = tip, 3 = request
  enum :message_type, { text: 0, image: 1, tip: 2, request: 3 }, default: :text

  validates :content, presence: true, length: { maximum: 2000 }

  after_create_commit :update_conversation_timestamp
  after_create_commit :increment_unread_count
  after_create_commit :broadcast_message

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

  # Get the recipient of this message
  def recipient
    if sender_id == conversation.fan_id
      conversation.creator
    else
      conversation.fan
    end
  end

  private

  def update_conversation_timestamp
    conversation.update(last_message_at: created_at)
  end

  def increment_unread_count
    if sender_id == conversation.fan_id
      # Fan sent message, increment creator's unread count
      conversation.increment!(:unread_creator_count)
    else
      # Creator sent message, increment fan's unread count
      conversation.increment!(:unread_fan_count)
    end
  end

  def broadcast_message
    # Broadcast to both participants
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: 'new_message',
        message: ::MessageSerializer.new(self).as_json,
        conversation_id: conversation.id
      }
    )

    # Broadcast to recipient's notification channel
    ActionCable.server.broadcast(
      "notifications_#{recipient.id}",
      {
        type: 'new_message',
        conversation_id: conversation.id,
        sender_name: sender.name,
        preview: content.truncate(50),
        unread_count: conversation.unread_count_for(recipient)
      }
    )
  end
end


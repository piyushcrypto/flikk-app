class Conversation < ApplicationRecord
  belongs_to :fan, class_name: 'User'
  belongs_to :creator, class_name: 'User'
  has_many :messages, dependent: :destroy

  validates :fan_id, uniqueness: { scope: :creator_id, message: "already has a conversation with this creator" }

  # Optimized scopes using indexes
  scope :for_user, ->(user) { where(fan_id: user.id).or(where(creator_id: user.id)) }
  scope :ordered, -> { order(last_message_at: :desc) }
  scope :with_messages, -> { where.not(last_message_at: nil) }
  
  # Eager loading scopes for avoiding N+1
  scope :with_participants, -> { includes(:fan, :creator) }
  scope :with_last_message, -> { includes(messages: :sender) }

  # Get the other participant in the conversation (cached)
  def other_participant(user)
    @other_participants ||= {}
    @other_participants[user.id] ||= (user.id == fan_id ? creator : fan)
  end

  # Check if user is part of this conversation
  def participant?(user)
    fan_id == user.id || creator_id == user.id
  end

  # Get unread count for a specific user (no database query)
  def unread_count_for(user)
    if user.id == fan_id
      unread_fan_count
    else
      unread_creator_count
    end
  end

  # Mark all messages as read for a user - optimized batch update
  def mark_as_read_for!(user)
    return if unread_count_for(user).zero?

    if user.id == fan_id
      # Fan is reading - mark creator's messages as read
      # Use a single transaction for atomicity
      transaction do
        messages.where(sender_id: creator_id, read_at: nil).update_all(read_at: Time.current)
        update_column(:unread_fan_count, 0)
      end
    else
      # Creator is reading - mark fan's messages as read
      transaction do
        messages.where(sender_id: fan_id, read_at: nil).update_all(read_at: Time.current)
        update_column(:unread_creator_count, 0)
      end
    end

    # Broadcast read status to the other participant
    other = other_participant(user)
    ActionCable.server.broadcast(
      "notifications_#{other.id}",
      {
        type: 'messages_read',
        conversation_id: id,
        reader_id: user.id
      }
    )
  rescue => e
    Rails.logger.error("Failed to mark messages as read: #{e.message}")
    raise
  end

  # Get or create a conversation between fan and creator - with race condition handling
  def self.find_or_create_between(fan:, creator:)
    # Use find_or_create_by with rescue for race conditions
    find_or_create_by!(fan_id: fan.id, creator_id: creator.id)
  rescue ActiveRecord::RecordNotUnique
    # Another process created the conversation, find it
    find_by!(fan_id: fan.id, creator_id: creator.id)
  end

  # Last message - use association to leverage eager loading
  def last_message
    # If messages are already loaded, use them
    if messages.loaded?
      messages.max_by(&:created_at)
    else
      messages.order(created_at: :desc).limit(1).first
    end
  end

  # Last message text preview (truncated) - avoid loading full message
  def last_message_preview
    msg = last_message
    return nil unless msg
    msg.content.truncate(50)
  end

  # Efficiently get unread count without loading all conversations
  def self.total_unread_for_user(user)
    if user.fan?
      where(fan_id: user.id).sum(:unread_fan_count)
    elsif user.creator?
      where(creator_id: user.id).sum(:unread_creator_count)
    else
      0
    end
  end
end

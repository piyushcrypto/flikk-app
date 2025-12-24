class Conversation < ApplicationRecord
  belongs_to :fan, class_name: 'User'
  belongs_to :creator, class_name: 'User'
  has_many :messages, dependent: :destroy

  validates :fan_id, uniqueness: { scope: :creator_id, message: "already has a conversation with this creator" }

  scope :for_user, ->(user) { where(fan_id: user.id).or(where(creator_id: user.id)) }
  scope :ordered, -> { order(last_message_at: :desc) }
  scope :with_messages, -> { where.not(last_message_at: nil) }

  # Get the other participant in the conversation
  def other_participant(user)
    user.id == fan_id ? creator : fan
  end

  # Check if user is part of this conversation
  def participant?(user)
    fan_id == user.id || creator_id == user.id
  end

  # Get unread count for a specific user
  def unread_count_for(user)
    if user.id == fan_id
      unread_fan_count
    else
      unread_creator_count
    end
  end

  # Mark all messages as read for a user
  def mark_as_read_for!(user)
    if user.id == fan_id
      # Fan is reading - mark creator's messages as read
      messages.where(sender_id: creator_id).where(read_at: nil).update_all(read_at: Time.current)
      update(unread_fan_count: 0)
    else
      # Creator is reading - mark fan's messages as read
      messages.where(sender_id: fan_id).where(read_at: nil).update_all(read_at: Time.current)
      update(unread_creator_count: 0)
    end
  end

  # Get or create a conversation between fan and creator
  def self.find_or_create_between(fan:, creator:)
    find_or_create_by(fan_id: fan.id, creator_id: creator.id)
  end

  # Last message preview
  def last_message
    messages.order(created_at: :desc).first
  end

  # Last message text preview (truncated)
  def last_message_preview
    msg = last_message
    return nil unless msg
    msg.content.truncate(50)
  end
end


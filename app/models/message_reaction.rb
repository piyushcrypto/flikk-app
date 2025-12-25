class MessageReaction < ApplicationRecord
  belongs_to :message
  belongs_to :user

  # Available emoji reactions
  ALLOWED_EMOJIS = %w[❤️ 😂 😮 😢 😡 👍 👎 🔥 💯 🙏].freeze

  validates :emoji, presence: true, inclusion: { in: ALLOWED_EMOJIS, message: "is not a valid reaction" }
  validates :user_id, uniqueness: { scope: [:message_id, :emoji], message: "already reacted with this emoji" }

  after_create_commit :broadcast_reaction_added
  after_destroy_commit :broadcast_reaction_removed

  # Get reaction counts for a message
  def self.counts_for_message(message_id)
    where(message_id: message_id)
      .group(:emoji)
      .count
  end

  private

  def broadcast_reaction_added
    BroadcastReactionJob.perform_later(message_id, 'added', emoji, user_id)
  end

  def broadcast_reaction_removed
    BroadcastReactionJob.perform_later(message_id, 'removed', emoji, user_id)
  end
end


class MessageSerializer
  def initialize(message)
    @message = message
  end

  def as_json
    {
      id: @message.id,
      conversation_id: @message.conversation_id,
      sender_id: @message.sender_id,
      sender_name: @message.sender.name,
      sender_avatar: sender_avatar_url,
      content: @message.content,
      message_type: @message.message_type,
      read_at: @message.read_at,
      created_at: @message.created_at.iso8601,
      is_read: @message.read?
    }
  end

  private

  def sender_avatar_url
    if @message.sender.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(@message.sender.avatar, only_path: true)
    else
      nil
    end
  end
end


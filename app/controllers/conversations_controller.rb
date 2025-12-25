class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :messages]

  # GET /conversations
  def index
    # Optimized query with eager loading to avoid N+1
    @conversations = current_user.conversations
      .with_messages
      .with_participants
      .ordered
      .includes(messages: :sender)
      .limit(50)  # Pagination limit for performance
    
    respond_to do |format|
      format.html
      format.json { render json: conversations_json(@conversations) }
    end
  end

  # GET /conversations/:id
  def show
    @conversation.mark_as_read_for!(current_user)
    
    # Paginated messages - get latest 20, then reverse for chronological display
    @messages = @conversation.messages
      .order(created_at: :desc)
      .includes(:sender, :reactions)
      .limit(20)
      .reverse  # Reverse to show oldest first in the UI
    
    # Check if there are more messages to load
    @has_more_messages = @conversation.messages.count > 20
      
    @other_user = @conversation.other_participant(current_user)
    
    # Preload avatar for other user to avoid N+1 in serializer
    ActiveStorage::Attachment.where(
      record_type: 'User',
      record_id: @other_user.id,
      name: 'avatar'
    ).includes(:blob).load
    
    respond_to do |format|
      format.html
      format.json { 
        render json: {
          conversation: conversation_json(@conversation),
          messages: @messages.map { |m| message_json(m) },
          other_user: user_json(@other_user)
        }
      }
    end
  end

  # POST /conversations
  def create
    # Find or create conversation with a creator
    creator = User.verified_creators.find_by(id: params[:creator_id])
    
    unless creator
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: "Creator not found" }
        format.json { render json: { error: "Creator not found" }, status: :not_found }
      end
      return
    end
    
    if current_user.creator?
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: "Creators cannot initiate conversations" }
        format.json { render json: { error: "Creators cannot initiate conversations" }, status: :unprocessable_entity }
      end
      return
    end

    @conversation = Conversation.find_or_create_between(fan: current_user, creator: creator)
    
    respond_to do |format|
      format.html { redirect_to conversation_path(@conversation) }
      format.json { render json: conversation_json(@conversation), status: :created }
    end
  end

  # GET /conversations/:id/messages (for pagination/loading more)
  def messages
    limit = params.fetch(:limit, 20).to_i.clamp(1, 50)
    
    @messages = @conversation.messages.includes(:sender, :reactions)
    
    # For loading older messages (scrolling up)
    if params[:before_id].present?
      before_message = @conversation.messages.find_by(id: params[:before_id])
      if before_message
        @messages = @messages.where('created_at < ?', before_message.created_at)
      end
    end
    
    # For loading newer messages (if needed)
    if params[:after_id].present?
      after_message = @conversation.messages.find_by(id: params[:after_id])
      if after_message
        @messages = @messages.where('created_at > ?', after_message.created_at)
      end
    end
    
    # Get messages in descending order, then reverse for chronological display
    @messages = @messages.order(created_at: :desc).limit(limit + 1).to_a
    
    # Check if there are more messages
    has_more = @messages.size > limit
    @messages = @messages.first(limit).reverse
    
    render json: {
      messages: @messages.map { |m| message_json(m) },
      has_more: has_more
    }
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(id: params[:id])
    
    unless @conversation&.participant?(current_user)
      respond_to do |format|
        format.html { redirect_to conversations_path, alert: "You don't have access to this conversation" }
        format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
      end
    end
  end

  def conversations_json(conversations)
    conversations.map { |c| conversation_json(c) }
  end

  def conversation_json(conversation)
    other = conversation.other_participant(current_user)
    {
      id: conversation.id,
      other_user: user_json(other),
      last_message_at: conversation.last_message_at&.iso8601,
      last_message_preview: conversation.last_message_preview,
      unread_count: conversation.unread_count_for(current_user)
    }
  end

  def message_json(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      sender_avatar: message.sender.avatar.attached? ? url_for(message.sender.avatar) : nil,
      content: message.content,
      message_type: message.message_type,
      read_at: message.read_at&.iso8601,
      created_at: message.created_at.iso8601,
      is_read: message.read?
    }
  end

  def user_json(user)
    {
      id: user.id,
      name: user.name,
      username: user.username,
      display_handle: user.display_handle,
      avatar_url: user.avatar.attached? ? url_for(user.avatar) : nil,
      is_live: user.is_live?,
      is_creator: user.creator?
    }
  end
end

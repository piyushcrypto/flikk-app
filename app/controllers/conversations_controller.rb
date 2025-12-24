class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :messages]

  # GET /conversations
  def index
    @conversations = current_user.conversations.with_messages.includes(:fan, :creator, :messages)
    
    respond_to do |format|
      format.html
      format.json { render json: conversations_json(@conversations) }
    end
  end

  # GET /conversations/:id
  def show
    @conversation.mark_as_read_for!(current_user)
    @messages = @conversation.messages.ordered.includes(:sender)
    @other_user = @conversation.other_participant(current_user)
    
    respond_to do |format|
      format.html
      format.json { 
        render json: {
          conversation: conversation_json(@conversation),
          messages: @messages.map { |m| MessageSerializer.new(m).as_json },
          other_user: user_json(@other_user)
        }
      }
    end
  end

  # POST /conversations
  def create
    # Find or create conversation with a creator
    creator = User.verified_creators.find(params[:creator_id])
    
    if current_user.creator?
      render json: { error: "Creators cannot initiate conversations" }, status: :unprocessable_entity
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
    @messages = @conversation.messages.ordered
    
    if params[:before].present?
      @messages = @messages.where('created_at < ?', Time.parse(params[:before]))
    end
    
    @messages = @messages.limit(50)
    
    render json: @messages.map { |m| MessageSerializer.new(m).as_json }
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
    
    unless @conversation.participant?(current_user)
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


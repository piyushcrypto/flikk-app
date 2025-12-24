class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  # POST /conversations/:conversation_id/messages
  def create
    @message = @conversation.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      respond_to do |format|
        format.html { redirect_to conversation_path(@conversation) }
        format.json { 
          render json: {
            id: @message.id,
            conversation_id: @message.conversation_id,
            sender_id: @message.sender_id,
            sender_name: current_user.name,
            sender_avatar: current_user.avatar.attached? ? url_for(current_user.avatar) : nil,
            content: @message.content,
            message_type: @message.message_type,
            read_at: nil,
            created_at: @message.created_at.iso8601,
            is_read: false
          }, status: :created 
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to conversation_path(@conversation), alert: @message.errors.full_messages.join(', ') }
        format.json { render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # POST /conversations/:conversation_id/messages/mark_read
  def mark_read
    @conversation.mark_as_read_for!(current_user)
    
    respond_to do |format|
      format.html { redirect_to conversation_path(@conversation) }
      format.json { render json: { success: true, unread_count: 0 } }
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(id: params[:conversation_id])
    
    unless @conversation&.participant?(current_user)
      respond_to do |format|
        format.html { redirect_to conversations_path, alert: "You don't have access to this conversation" }
        format.json { render json: { error: "Unauthorized" }, status: :unauthorized }
      end
    end
  end

  def message_params
    params.require(:message).permit(:content, :message_type)
  end
end

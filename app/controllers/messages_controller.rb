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
        format.json { render json: MessageSerializer.new(@message).as_json, status: :created }
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
    @conversation = Conversation.find(params[:conversation_id])
    
    unless @conversation.participant?(current_user)
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


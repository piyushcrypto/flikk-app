class MessageReactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message
  before_action :authorize_reaction

  # POST /messages/:message_id/reactions
  def create
    @reaction = @message.reactions.find_or_initialize_by(
      user: current_user,
      emoji: params[:emoji]
    )

    if @reaction.new_record?
      if @reaction.save
        render json: { 
          success: true, 
          action: 'added',
          emoji: @reaction.emoji,
          reaction_counts: @message.reaction_counts
        }
      else
        render json: { errors: @reaction.errors.full_messages }, status: :unprocessable_entity
      end
    else
      # Already reacted - toggle off (remove)
      @reaction.destroy
      render json: { 
        success: true, 
        action: 'removed',
        emoji: params[:emoji],
        reaction_counts: @message.reaction_counts
      }
    end
  end

  # DELETE /messages/:message_id/reactions
  def destroy
    @reaction = @message.reactions.find_by(user: current_user, emoji: params[:emoji])
    
    if @reaction&.destroy
      render json: { 
        success: true, 
        action: 'removed',
        emoji: params[:emoji],
        reaction_counts: @message.reaction_counts
      }
    else
      render json: { error: 'Reaction not found' }, status: :not_found
    end
  end

  private

  def set_message
    @message = Message.find(params[:message_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Message not found' }, status: :not_found
  end

  def authorize_reaction
    # User must be a participant in the conversation
    unless @message.conversation.participant?(current_user)
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
    
    # Users can only react to the OTHER person's messages, not their own
    if @message.sender_id == current_user.id
      render json: { error: "You can't react to your own messages" }, status: :forbidden
    end
  end
end


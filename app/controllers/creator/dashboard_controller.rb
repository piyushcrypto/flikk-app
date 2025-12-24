class Creator::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_creator
  before_action :ensure_onboarding_complete

  def show
    @creator = current_user
    
    # Optimized conversation query with eager loading
    @conversations = current_user.conversations_as_creator
      .with_messages
      .with_participants
      .ordered
      .limit(10)
      
    @unread_messages_count = Conversation.total_unread_for_user(current_user)
    
    # Stats - use efficient counting
    @total_earnings = 0
    @total_messages = current_user.conversations_as_creator
      .joins(:messages)
      .count
    @total_followers = current_user.followers_count || 0
  end

  def go_live
    current_user.go_live!
    
    # Broadcast live status to all connected clients
    broadcast_live_status(true)
    
    respond_to do |format|
      format.html { redirect_to creator_dashboard_path, notice: "You are now live!" }
      format.json { render json: { success: true, is_live: true } }
    end
  end

  def go_offline
    current_user.go_offline!
    
    # Broadcast offline status
    broadcast_live_status(false)
    
    respond_to do |format|
      format.html { redirect_to creator_dashboard_path, notice: "You are now offline." }
      format.json { render json: { success: true, is_live: false } }
    end
  end

  private

  def ensure_creator
    unless current_user.creator?
      redirect_to dashboard_path, alert: "Only creators can access this area."
    end
  end

  def ensure_onboarding_complete
    if current_user.needs_onboarding?
      redirect_to creator_onboarding_path
    end
  end

  def broadcast_live_status(is_live)
    # Broadcast to a global channel for live status updates
    ActionCable.server.broadcast(
      "live_creators",
      {
        type: 'live_status_changed',
        creator_id: current_user.id,
        creator_name: current_user.name,
        is_live: is_live
      }
    )
  rescue => e
    Rails.logger.error("Failed to broadcast live status: #{e.message}")
  end
end

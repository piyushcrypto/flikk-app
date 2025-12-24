class Creator::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_creator
  before_action :ensure_onboarding_complete

  def show
    @creator = current_user
    
    # Get conversations with messages
    @conversations = current_user.conversations_as_creator.with_messages.ordered.limit(10)
    @unread_messages_count = current_user.unread_messages_count
    
    # Stats
    @total_earnings = 0
    @total_messages = current_user.conversations_as_creator.joins(:messages).count
    @total_followers = current_user.followers_count || 0
  end

  def go_live
    current_user.go_live!
    respond_to do |format|
      format.html { redirect_to creator_dashboard_path, notice: "You are now live!" }
      format.json { render json: { success: true, is_live: true } }
    end
  end

  def go_offline
    current_user.go_offline!
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
end


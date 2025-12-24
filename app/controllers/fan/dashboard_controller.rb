class Fan::DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    # Redirect creators to their dashboard
    if current_user.creator?
      redirect_to creator_dashboard_path
      return
    end

    @heart_balance = 0 # TODO: Implement hearts system
    
    # Optimized queries with select to only load needed columns
    # Live creators (creators who have clicked "Go Live")
    @live_creators = User.live_creators
      .select(:id, :name, :username, :category, :is_live, :followers_count)
      .with_attached_avatar
      .limit(10)
    
    # Popular creators (by follower count) - cached for 5 minutes
    @popular_creators = Rails.cache.fetch("popular_creators", expires_in: 5.minutes) do
      User.popular
        .select(:id, :name, :username, :category, :is_live, :followers_count)
        .with_attached_avatar
        .limit(12)
        .to_a
    end
    
    # Suggested creators (random verified creators)
    # Use a more efficient random selection for large datasets
    @suggested_creators = User.verified_creators
      .select(:id, :name, :username, :category, :is_live, :followers_count)
      .with_attached_avatar
      .order(Arel.sql("RANDOM()"))
      .limit(10)
    
    # TODO: Implement following system
    @following_creators = []
    
    # Messaging - only load counts and minimal data
    @unread_messages_count = Conversation.total_unread_for_user(current_user)
    @active_chats = current_user.conversations
      .with_messages
      .with_participants
      .ordered
      .limit(5)
  end
end

class Fan::DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    # Redirect creators to their dashboard
    if current_user.creator?
      redirect_to creator_dashboard_path
      return
    end

    @heart_balance = current_user.respond_to?(:heart_balance) ? (current_user.heart_balance || 0) : 0
    
    # Live creators (creators who have clicked "Go Live")
    @live_creators = User.live_creators
      .includes(avatar_attachment: :blob)
      .limit(10)
    
    # Popular creators (by follower count) - cached for 5 minutes
    @popular_creators = Rails.cache.fetch("popular_creators", expires_in: 5.minutes) do
      User.popular
        .includes(avatar_attachment: :blob)
        .limit(12)
        .to_a
    end
    
    # Suggested creators (random verified creators)
    @suggested_creators = User.verified_creators
      .includes(avatar_attachment: :blob)
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

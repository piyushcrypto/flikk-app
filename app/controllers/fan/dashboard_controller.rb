class Fan::DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    # Redirect creators to their dashboard
    if current_user.creator?
      redirect_to creator_dashboard_path
      return
    end

    # Get real data from database
    @heart_balance = 0 # TODO: Implement hearts system
    
    # Live creators (creators who have clicked "Go Live")
    @live_creators = User.live_creators.limit(10)
    
    # Popular creators (by follower count)
    @popular_creators = User.popular.limit(12)
    
    # Suggested creators (random verified creators)
    @suggested_creators = User.verified_creators.order('RANDOM()').limit(10)
    
    # TODO: Implement following system
    @following_creators = []
    
    # TODO: Implement messaging system
    @active_chats = []
  end
end


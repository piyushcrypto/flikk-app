class PagesController < ApplicationController
  def landing
    # Redirect logged in users to appropriate dashboard
    if user_signed_in?
      if current_user.creator?
        redirect_to creator_dashboard_path
      else
        redirect_to dashboard_path
      end
    end
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def content_guidelines
  end

  def creator_terms
  end

  def fan_terms
  end
end

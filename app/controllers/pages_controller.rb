class PagesController < ApplicationController
  def landing
    # Redirect logged in users to dashboard
    redirect_to dashboard_path if user_signed_in?
  end

  def dashboard
    authenticate_user!
    flash.now[:notice] = "Welcome! You are logged in as a #{current_user.role.titleize}."
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


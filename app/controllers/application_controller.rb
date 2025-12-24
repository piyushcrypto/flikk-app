class ApplicationController < ActionController::Base
  before_action :check_creator_onboarding

  protected

  # Redirect to dashboard or onboarding after sign in
  def after_sign_in_path_for(resource)
    if resource.needs_onboarding?
      creator_onboarding_path
    else
      dashboard_path
    end
  end

  # Redirect to landing page after sign out
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  # Redirect creators who haven't completed onboarding
  def check_creator_onboarding
    return unless user_signed_in?
    return unless current_user.needs_onboarding?
    return if onboarding_controller?
    return if devise_controller?
    return if pages_controller_public_action?

    redirect_to creator_onboarding_path
  end

  def onboarding_controller?
    controller_path.start_with?('creator/onboarding')
  end

  def pages_controller_public_action?
    controller_name == 'pages' && %w[landing privacy_policy terms_of_service content_guidelines creator_terms fan_terms].include?(action_name)
  end
end

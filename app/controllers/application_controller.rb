class ApplicationController < ActionController::Base
  protected

  # Redirect to dashboard after sign in
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  # Redirect to landing page after sign out
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end

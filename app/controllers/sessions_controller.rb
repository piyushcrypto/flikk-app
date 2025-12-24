class SessionsController < Devise::SessionsController
  # POST /users/sign_in
  def create
    super do |resource|
      # Set encrypted cookie for Action Cable authentication
      cookies.encrypted[:user_id] = resource.id
    end
  end

  # DELETE /users/sign_out
  def destroy
    # Clear the Action Cable cookie
    cookies.delete(:user_id)
    super
  end

  protected

  def after_sign_in_path_for(resource)
    dashboard_path
  end
end


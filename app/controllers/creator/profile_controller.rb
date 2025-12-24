class Creator::ProfileController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_creator

  def show
    @creator = current_user
  end

  def edit
    @creator = current_user
  end

  def update
    @creator = current_user
    
    if @creator.update(profile_params)
      redirect_to creator_profile_path, notice: "Profile updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def ensure_creator
    unless current_user.creator?
      redirect_to dashboard_path, alert: "Only creators can access this area."
    end
  end

  def profile_params
    params.require(:user).permit(
      :name, :username, :instagram_handle, :bio, :category,
      :avatar, :cover_image
    )
  end
end


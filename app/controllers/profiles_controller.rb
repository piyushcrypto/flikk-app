class ProfilesController < ApplicationController
  def show
    @creator = User.verified_creators.find_by!(username: params[:username])
    @services = @creator.creator_services.active
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Creator not found"
  end
end


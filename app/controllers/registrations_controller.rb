class RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]

  # GET /register/fan
  def new_fan
    build_resource({})
    @role = :fan
    @show_step_2 = false
    render :new
  end

  # GET /register/creator
  def new_creator
    build_resource({})
    @role = :creator
    @show_step_2 = false
    render :new
  end

  # POST /register
  def create
    build_resource(sign_up_params)
    
    # Set role based on the registration path
    resource.role = params[:user][:role] if params[:user][:role].present?

    resource.save
    yield resource if block_given?
    
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      # Preserve form state on errors
      @role = resource.role&.to_sym || :fan
      @show_step_2 = true # Show step 2 since user already entered email
      @submitted_email = params[:user][:email]
      @submitted_name = params[:user][:name]
      render :new, status: :unprocessable_entity
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
  end

  def after_sign_up_path_for(resource)
    dashboard_path
  end
end


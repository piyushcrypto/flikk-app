class Creator::OnboardingController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_creator
  before_action :redirect_if_completed, except: [:complete]

  # GET /creator/onboarding
  def show
    redirect_to_current_step
  end

  # GET /creator/onboarding/profile (Step 1)
  def profile
    @suggested_username = current_user.username.presence || User.generate_unique_username(current_user.name)
  end

  # PATCH /creator/onboarding/profile
  def update_profile
    @suggested_username = params[:user][:username]
    has_errors = false

    # Validate required fields
    if params[:user][:instagram_handle].blank?
      current_user.errors.add(:instagram_handle, "can't be blank")
      has_errors = true
    end

    if params[:user][:username].blank?
      current_user.errors.add(:username, "can't be blank")
      has_errors = true
    end

    # Validate avatar is mandatory for creators
    if !current_user.avatar.attached? && !params[:user][:avatar].present?
      current_user.errors.add(:avatar, "is required for creators")
      has_errors = true
    end

    if has_errors
      render :profile, status: :unprocessable_entity
      return
    end

    if current_user.update(profile_params.merge(onboarding_step: 2))
      redirect_to creator_onboarding_services_path, notice: "Profile saved!"
    else
      render :profile, status: :unprocessable_entity
    end
  end

  # GET /creator/onboarding/services (Step 2)
  def services
    @selected_services = current_user.creator_services.pluck(:service_type)
  end

  # PATCH /creator/onboarding/services
  def update_services
    selected_service_types = params[:services] || []
    
    # Remove unselected services
    current_user.creator_services.where.not(service_type: selected_service_types).destroy_all
    
    # Add new services
    selected_service_types.each do |service_type|
      current_user.creator_services.find_or_create_by(service_type: service_type) do |service|
        service.is_active = true
      end
    end

    if selected_service_types.any?
      current_user.update(onboarding_step: 3)
      redirect_to creator_onboarding_availability_path, notice: "Services saved!"
    else
      flash.now[:alert] = "Please select at least one service"
      @selected_services = []
      render :services, status: :unprocessable_entity
    end
  end

  # GET /creator/onboarding/availability (Step 3)
  def availability
    @slots_by_day = current_user.availability_slots.group_by(&:day_of_week)
    @services = current_user.creator_services.active
  end

  # PATCH /creator/onboarding/availability
  def update_availability
    # Update pricing for services
    if params[:service_pricing].present?
      params[:service_pricing].each do |service_id, pricing|
        service = current_user.creator_services.find_by(id: service_id)
        next unless service
        
        service.update(
          price_per_slot: pricing[:price_per_slot],
          price_per_message: pricing[:price_per_message]
        )
      end
    end

    # Validate at least one slot or dynamic pricing
    has_slots = current_user.availability_slots.any?
    has_message_pricing = current_user.creator_services.where('price_per_message > 0').any?

    if has_slots || has_message_pricing
      current_user.update(onboarding_step: 4, onboarding_completed: true)
      redirect_to creator_onboarding_complete_path
    else
      flash.now[:alert] = "Please add at least one availability slot or set message pricing"
      @slots_by_day = current_user.availability_slots.group_by(&:day_of_week)
      @services = current_user.creator_services.active
      render :availability, status: :unprocessable_entity
    end
  end

  # POST /creator/onboarding/slots
  def create_slot
    @slot = current_user.availability_slots.build(slot_params)
    @slot.is_active = true

    if @slot.save
      respond_to do |format|
        format.html { redirect_to creator_onboarding_availability_path, notice: "Slot added!" }
        format.turbo_stream
        format.json { render json: { success: true, slot: slot_json(@slot) } }
      end
    else
      respond_to do |format|
        format.html { 
          flash[:alert] = @slot.errors.full_messages.join(', ')
          redirect_to creator_onboarding_availability_path
        }
        format.json { render json: { success: false, errors: @slot.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /creator/onboarding/slots/:id
  def destroy_slot
    @slot = current_user.availability_slots.find(params[:id])
    @slot.destroy

    respond_to do |format|
      format.html { redirect_to creator_onboarding_availability_path, notice: "Slot removed" }
      format.turbo_stream
      format.json { render json: { success: true } }
    end
  end

  # GET /creator/onboarding/complete
  def complete
    unless current_user.onboarding_completed?
      redirect_to creator_onboarding_path
      return
    end
  end

  # GET /creator/onboarding/check_username
  def check_username
    username = params[:username].to_s.strip
    available = User.username_available?(username, current_user.id)
    
    render json: { 
      available: available,
      message: available ? "Username is available!" : "Username is already taken"
    }
  end

  private

  def ensure_creator
    unless current_user.creator?
      redirect_to dashboard_path, alert: "Only creators can access onboarding"
    end
  end

  def redirect_if_completed
    if current_user.onboarding_completed?
      redirect_to dashboard_path
    end
  end

  def redirect_to_current_step
    case current_user.current_onboarding_step
    when 1
      redirect_to creator_onboarding_profile_path
    when 2
      redirect_to creator_onboarding_services_path
    when 3
      redirect_to creator_onboarding_availability_path
    else
      redirect_to creator_onboarding_complete_path
    end
  end

  def profile_params
    params.require(:user).permit(:username, :instagram_handle, :bio, :avatar)
  end

  def slot_params
    params.require(:availability_slot).permit(:day_of_week, :start_time, :end_time)
  end

  def slot_json(slot)
    {
      id: slot.id,
      day_of_week: slot.day_of_week,
      day_name: slot.day_name,
      start_time: slot.start_time.strftime('%H:%M'),
      end_time: slot.end_time.strftime('%H:%M'),
      time_range: slot.time_range
    }
  end
end


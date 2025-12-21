Rails.application.routes.draw do
  # Devise routes with custom registrations controller
  devise_for :users, controllers: {
    registrations: 'registrations',
    sessions: 'sessions'
  }

  # Custom registration routes for different roles (scoped under devise)
  devise_scope :user do
    get 'register/fan', to: 'registrations#new_fan', as: :fan_registration
    get 'register/creator', to: 'registrations#new_creator', as: :creator_registration
  end

  # Application routes
  root 'pages#landing'
  get 'dashboard', to: 'pages#dashboard', as: :dashboard

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end

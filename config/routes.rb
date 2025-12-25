require 'sidekiq/web'

Rails.application.routes.draw do
  # Sidekiq Web UI (protected by admin auth)
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

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

  # Creator Onboarding
  namespace :creator do
    get 'onboarding', to: 'onboarding#show', as: :onboarding
    get 'onboarding/profile', to: 'onboarding#profile', as: :onboarding_profile
    patch 'onboarding/profile', to: 'onboarding#update_profile'
    get 'onboarding/services', to: 'onboarding#services', as: :onboarding_services
    patch 'onboarding/services', to: 'onboarding#update_services'
    get 'onboarding/availability', to: 'onboarding#availability', as: :onboarding_availability
    patch 'onboarding/availability', to: 'onboarding#update_availability'
    post 'onboarding/slots', to: 'onboarding#create_slot', as: :onboarding_slots
    delete 'onboarding/slots/:id', to: 'onboarding#destroy_slot', as: :onboarding_slot
    get 'onboarding/complete', to: 'onboarding#complete', as: :onboarding_complete
    get 'onboarding/check_username', to: 'onboarding#check_username', as: :check_username
    
    # Creator Dashboard
    get 'dashboard', to: 'dashboard#show', as: :dashboard
    post 'go_live', to: 'dashboard#go_live', as: :go_live
    post 'go_offline', to: 'dashboard#go_offline', as: :go_offline
    
    # Profile management
    get 'profile', to: 'profile#show', as: :profile
    get 'profile/edit', to: 'profile#edit', as: :edit_profile
    patch 'profile', to: 'profile#update'
  end

  # Application routes
  root 'pages#landing'
  
  # Fan Dashboard
  get 'dashboard', to: 'fan/dashboard#show', as: :dashboard

  # Messaging
  resources :conversations, only: [:index, :show, :create] do
    member do
      get :messages
    end
    resources :messages, only: [:create] do
      collection do
        post :mark_read
      end
    end
  end

  # Message reactions
  resources :messages, only: [] do
    resources :reactions, controller: 'message_reactions', only: [:create, :destroy]
  end

  # Legal pages
  get 'privacy-policy', to: 'pages#privacy_policy', as: :privacy_policy
  get 'terms-of-service', to: 'pages#terms_of_service', as: :terms_of_service
  get 'content-guidelines', to: 'pages#content_guidelines', as: :content_guidelines
  get 'creator-terms', to: 'pages#creator_terms', as: :creator_terms
  get 'fan-terms', to: 'pages#fan_terms', as: :fan_terms

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Public Creator Profile (must be last to catch /:username)
  get ':username', to: 'profiles#show', as: :public_profile, constraints: { username: /[a-zA-Z0-9_]+/ }
end

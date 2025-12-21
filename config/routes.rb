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

  # Legal pages
  get 'privacy-policy', to: 'pages#privacy_policy', as: :privacy_policy
  get 'terms-of-service', to: 'pages#terms_of_service', as: :terms_of_service
  get 'content-guidelines', to: 'pages#content_guidelines', as: :content_guidelines
  get 'creator-terms', to: 'pages#creator_terms', as: :creator_terms
  get 'fan-terms', to: 'pages#fan_terms', as: :fan_terms

  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end

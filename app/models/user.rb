class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role enum: 0 = fan, 1 = creator, 2 = admin
  enum :role, { fan: 0, creator: 1, admin: 2 }, default: :fan

  # Active Storage attachments for profile images
  has_one_attached :avatar
  has_one_attached :cover_image

  # Associations for creators
  has_many :creator_services, dependent: :destroy
  has_many :availability_slots, dependent: :destroy

  # Scopes for querying creators
  scope :creators, -> { where(role: :creator) }
  scope :verified_creators, -> { creators.where(onboarding_completed: true) }
  scope :live_creators, -> { verified_creators.where(is_live: true) }
  scope :popular, -> { verified_creators.order(followers_count: :desc) }
  scope :recently_active, -> { verified_creators.order(updated_at: :desc) }

  validates :name, presence: true
  validates :role, presence: true
  validates :username, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :username, format: { with: /\A[a-zA-Z0-9_]+\z/, message: "can only contain letters, numbers, and underscores" }, allow_blank: true
  validates :username, length: { minimum: 3, maximum: 30 }, allow_blank: true
  validates :instagram_handle, format: { with: /\A[a-zA-Z0-9._]+\z/, message: "can only contain letters, numbers, periods, and underscores" }, allow_blank: true
  
  # Avatar validations
  validate :avatar_content_type, if: -> { avatar.attached? }
  validate :avatar_size, if: -> { avatar.attached? }

  # Onboarding steps for creators
  # 1 = Profile (instagram, username)
  # 2 = Services
  # 3 = Availability & Pricing
  # 4 = Completed
  ONBOARDING_STEPS = {
    profile: 1,
    services: 2,
    availability: 3,
    completed: 4
  }.freeze

  SERVICE_TYPES = [
    { key: 'roasting', label: 'Roasting', description: 'Humorous roasts and burns', icon: '🔥' },
    { key: 'flirting', label: 'Flirting', description: 'Playful flirty conversations', icon: '💕' },
    { key: 'on_demand', label: 'On Demand Content', description: 'Custom content on request', icon: '📸' },
    { key: 'profile_review', label: 'Profile Reviews', description: 'Dating profile reviews', icon: '👀' },
    { key: 'direct_messages', label: 'Direct Messages', description: 'Personal 1-on-1 chats', icon: '💬' },
    { key: 'ugc_videos', label: 'UGC Videos', description: 'User-generated content videos', icon: '🎬' },
    { key: 'advice', label: 'Advice & Guidance', description: 'Personal advice sessions', icon: '💡' },
    { key: 'shoutouts', label: 'Shoutouts', description: 'Personalized shoutouts', icon: '📣' }
  ].freeze

  DAYS_OF_WEEK = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday].freeze

  # Avatar variants for different sizes
  def avatar_thumbnail
    avatar.variant(resize_to_fill: [100, 100]) if avatar.attached?
  end

  def avatar_medium
    avatar.variant(resize_to_fill: [300, 300]) if avatar.attached?
  end

  def avatar_large
    avatar.variant(resize_to_fill: [500, 500]) if avatar.attached?
  end

  # Avatar URL helper - returns S3 URL or placeholder
  def avatar_url_or_default
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      nil
    end
  end

  # Check if avatar is required (for creators during onboarding)
  def avatar_required?
    creator? && onboarding_step.to_i >= 1
  end

  # Check if creator needs onboarding
  def needs_onboarding?
    creator? && !onboarding_completed?
  end

  # Go live functionality
  def go_live!
    update(is_live: true, last_live_at: Time.current)
  end

  def go_offline!
    update(is_live: false)
  end

  # Display handle
  def display_handle
    username.present? ? "@#{username}" : "@#{email.split('@').first}"
  end

  # Instagram URL
  def instagram_url
    instagram_handle.present? ? "https://instagram.com/#{instagram_handle}" : nil
  end

  # Formatted followers count
  def formatted_followers
    count = followers_count.to_i
    if count >= 1_000_000
      "#{(count / 1_000_000.0).round(1)}M"
    elsif count >= 1_000
      "#{(count / 1_000.0).round(1)}K"
    else
      count.to_s
    end
  end

  # Get current onboarding step (default to 1 if not set)
  def current_onboarding_step
    onboarding_step || 1
  end

  # Check if specific step is completed
  def step_completed?(step)
    current_onboarding_step > ONBOARDING_STEPS[step]
  end

  # Generate unique username from name
  def self.generate_unique_username(name)
    base = name.to_s.downcase.gsub(/[^a-z0-9]/, '')
    base = 'user' if base.blank?
    
    username = base
    counter = 1
    
    # Use a hash-based approach for uniqueness
    while exists?(username: username)
      # Add random suffix for better distribution
      suffix = counter < 10 ? counter.to_s : SecureRandom.hex(3)
      username = "#{base}#{suffix}"
      counter += 1
    end
    
    username
  end

  # Check if username is available (for AJAX validation)
  def self.username_available?(username, exclude_user_id = nil)
    return false if username.blank?
    return false unless username.match?(/\A[a-zA-Z0-9_]+\z/)
    return false if username.length < 3 || username.length > 30
    
    query = where('LOWER(username) = ?', username.downcase)
    query = query.where.not(id: exclude_user_id) if exclude_user_id
    !query.exists?
  end

  private

  def avatar_content_type
    unless avatar.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
      errors.add(:avatar, 'must be a JPEG, PNG, GIF, or WEBP image')
    end
  end

  def avatar_size
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, 'must be less than 5MB')
    end
  end
end

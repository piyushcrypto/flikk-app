class CreatorService < ApplicationRecord
  belongs_to :user

  validates :service_type, presence: true
  validates :service_type, inclusion: { in: User::SERVICE_TYPES.map { |s| s[:key] } }
  validates :price_per_slot, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :price_per_message, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(is_active: true) }

  def service_info
    User::SERVICE_TYPES.find { |s| s[:key] == service_type }
  end

  def label
    service_info&.dig(:label) || service_type.titleize
  end

  def icon
    service_info&.dig(:icon) || '⭐'
  end
end

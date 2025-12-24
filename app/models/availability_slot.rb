class AvailabilitySlot < ApplicationRecord
  belongs_to :user

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time
  validate :no_overlapping_slots

  scope :active, -> { where(is_active: true) }
  scope :for_day, ->(day) { where(day_of_week: day) }

  def day_name
    User::DAYS_OF_WEEK[day_of_week]
  end

  def time_range
    "#{start_time.strftime('%I:%M %p')} - #{end_time.strftime('%I:%M %p')}"
  end

  def duration_minutes
    ((end_time - start_time) / 60).to_i
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time
    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end

  def no_overlapping_slots
    return unless user && day_of_week && start_time && end_time

    overlapping = user.availability_slots
      .where(day_of_week: day_of_week)
      .where.not(id: id)
      .where('(start_time < ? AND end_time > ?) OR (start_time < ? AND end_time > ?) OR (start_time >= ? AND end_time <= ?)',
             end_time, start_time, end_time, start_time, start_time, end_time)

    if overlapping.exists?
      errors.add(:base, "This slot overlaps with an existing slot")
    end
  end
end

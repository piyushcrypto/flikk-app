class CreateAvailabilitySlots < ActiveRecord::Migration[7.1]
  def change
    create_table :availability_slots do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :day_of_week
      t.time :start_time
      t.time :end_time
      t.boolean :is_active

      t.timestamps
    end
  end
end

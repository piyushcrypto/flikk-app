class CreateCreatorServices < ActiveRecord::Migration[7.1]
  def change
    create_table :creator_services do |t|
      t.references :user, null: false, foreign_key: true
      t.string :service_type
      t.text :description
      t.decimal :price_per_slot
      t.decimal :price_per_message
      t.boolean :is_active

      t.timestamps
    end
  end
end

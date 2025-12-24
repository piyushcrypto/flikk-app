class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.bigint :fan_id, null: false
      t.bigint :creator_id, null: false
      t.datetime :last_message_at
      t.integer :unread_fan_count, default: 0
      t.integer :unread_creator_count, default: 0

      t.timestamps
    end

    add_index :conversations, :fan_id
    add_index :conversations, :creator_id
    add_index :conversations, [:fan_id, :creator_id], unique: true
    add_index :conversations, :last_message_at
    add_foreign_key :conversations, :users, column: :fan_id
    add_foreign_key :conversations, :users, column: :creator_id
  end
end

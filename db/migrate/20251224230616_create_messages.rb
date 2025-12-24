class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.bigint :sender_id, null: false
      t.text :content, null: false
      t.datetime :read_at
      t.integer :message_type, default: 0

      t.timestamps
    end

    add_index :messages, :sender_id
    add_index :messages, :read_at
    add_index :messages, [:conversation_id, :created_at]
    add_foreign_key :messages, :users, column: :sender_id
  end
end

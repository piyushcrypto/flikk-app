class CreateMessageReactions < ActiveRecord::Migration[7.1]
  def change
    create_table :message_reactions do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji, null: false, limit: 10

      t.timestamps
    end

    # Ensure a user can only react once per emoji per message
    add_index :message_reactions, [:message_id, :user_id, :emoji], unique: true, name: 'index_reactions_on_message_user_emoji'
    
    # For counting reactions by emoji
    add_index :message_reactions, [:message_id, :emoji], name: 'index_reactions_on_message_emoji'
  end
end

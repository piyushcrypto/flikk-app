class AddScalabilityIndexes < ActiveRecord::Migration[7.1]
  def change
    # Users table - add composite indexes for common queries
    add_index :users, [:role, :onboarding_completed], name: "index_users_on_role_and_onboarding"
    add_index :users, [:role, :is_live], name: "index_users_on_role_and_live_status"
    add_index :users, [:role, :followers_count], name: "index_users_on_role_and_followers", order: { followers_count: :desc }
    
    # Messages table - add index for unread messages query
    add_index :messages, [:conversation_id, :sender_id, :read_at], name: "index_messages_on_conv_sender_read"
    
    # Conversations - add index for ordering by last message with messages
    add_index :conversations, [:fan_id, :last_message_at], name: "index_conversations_fan_last_msg", order: { last_message_at: :desc }
    add_index :conversations, [:creator_id, :last_message_at], name: "index_conversations_creator_last_msg", order: { last_message_at: :desc }
  end
end

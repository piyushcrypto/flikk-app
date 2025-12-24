class AddCreatorProfileToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true
    add_column :users, :instagram_handle, :string
    add_column :users, :bio, :text
    add_column :users, :avatar_url, :string
    add_column :users, :cover_url, :string
    add_column :users, :onboarding_step, :integer
    add_column :users, :onboarding_completed, :boolean
  end
end

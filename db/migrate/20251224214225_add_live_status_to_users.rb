class AddLiveStatusToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :is_live, :boolean
    add_column :users, :last_live_at, :datetime
    add_column :users, :category, :string
    add_column :users, :followers_count, :integer
  end
end

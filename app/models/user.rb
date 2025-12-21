class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Role enum: 0 = fan, 1 = creator, 2 = admin
  enum :role, { fan: 0, creator: 1, admin: 2 }, default: :fan

  validates :name, presence: true
  validates :role, presence: true
end

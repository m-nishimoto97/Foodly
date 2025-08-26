class User < ApplicationRecord
  acts_as_favoritor
  acts_as_voter
  has_many :scans
  has_many :recipes, through: :scans
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end

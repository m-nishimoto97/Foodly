class User < ApplicationRecord
  acts_as_favoritor
  acts_as_voter
  has_many :scans
  has_many :reviews, dependent: :destroy
  has_many :recipes, through: :scans
  has_many :schedules, dependent: :destroy
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end

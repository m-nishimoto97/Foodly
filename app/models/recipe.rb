class Recipe < ApplicationRecord
  acts_as_favoritable
  acts_as_votable
  belongs_to :scan
  has_many :reviews
  has_one :user, through: :scan
  validates :name, :duration, presence: true
end

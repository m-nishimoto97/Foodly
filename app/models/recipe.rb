class Recipe < ApplicationRecord
  belongs_to :scan
  has_one :user, through: :scan
  validates :name, :duration, presence: true
end

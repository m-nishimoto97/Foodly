class Recipe < ApplicationRecord
  belongs_to :scan
  belongs_to :user, through: :scans
  validates :name, :duration, presence: true
end

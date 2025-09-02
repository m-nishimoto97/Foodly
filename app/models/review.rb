class Review < ApplicationRecord
  belongs_to :recipe
  belongs_to :user

  has_one_attached :photo
  validates :rating, presence: true
end

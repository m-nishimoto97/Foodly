class Recipe < ApplicationRecord
  acts_as_favoritable
  acts_as_votable
  belongs_to :scan
  has_many :reviews, dependent: :destroy
  has_one :user, through: :scan
  validates :name, :duration, presence: true

  def average_rating
    reviews.average(:rating)
  end
end

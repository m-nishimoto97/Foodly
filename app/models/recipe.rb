class Recipe < ApplicationRecord
  acts_as_favoritable
  acts_as_votable
  belongs_to :scan
  has_many :reviews, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_one :user, through: :scan
  has_one_attached :photo
  validates :name, :duration, presence: true
  after_commit :async_update, on: [:create]

  def average_rating
    reviews.average(:rating)
  end

  private

  def async_update
    ImageGeneratorJob.perform_later(self.id)
  end
end

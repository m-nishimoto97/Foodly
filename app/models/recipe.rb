# app/models/recipe.rb
class Recipe < ApplicationRecord
  acts_as_favoritable
  acts_as_votable

  belongs_to :scan

  has_one :user, through: :scan
  has_one_attached :photo

  has_many :schedules, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :recipe_tags, dependent: :destroy
  has_many :tags, through: :recipe_tags

  # For Embeddings
  has_neighbors :embedding
  before_validation :set_embedding, on: :create

  validates :name, :duration, presence: true

  after_commit :async_update, on: [:create]

  enum difficulty: { easy: 1, medium: 2, hard: 3 }

  # ---- Scopes (as you had) ----
  scope :with_ingredient, ->(q) { q.present? ? where("ingredients ILIKE ?", "%#{sanitize_sql_like(q)}%") : all }
  scope :by_cuisine,      ->(c) { c.present? ? where(cuisine: c) : all }
  scope :by_diet,         ->(d) { d.present? ? where(diet: d) : all }
  scope :by_method,       ->(m) { m.present? ? where(method: m) : all }
  scope :by_meal_type,    ->(t) { t.present? ? where(meal_type: t) : all }
  scope :by_time_lte,     ->(min){ min.present? ? where("duration <= ?", min) : all }
  scope :by_difficulty,   ->(lvl){ lvl.present? ? where(difficulty: lvl) : all }
  scope :by_price_lte,    ->(c) { c.present? ? where("price_per_serving_cents <= ?", c) : all }
  scope :calories_lte,    ->(k) { k.present? ? where("calories_per_serving <= ?", k) : all }

  scope :in_season, ->(date = Date.today) {
    where("(best_season_start IS NULL AND best_season_end IS NULL) OR (best_season_start <= ? AND best_season_end >= ?)", date, date)
  }
  scope :with_tag, ->(name) { name.present? ? joins(:tags).where(tags: { name: name }) : all }

  def average_rating
    reviews.average(:rating)
  end

  # Safe accessor if ingredients is stored as a JSON string
  def ingredients_hash
    v = self.ingredients
    return v if v.is_a?(Hash)
    JSON.parse(v.presence || "{}")
  rescue JSON::ParserError
    {}
  end

  def set_embedding
    self.embedding = RubyLLM.embed("Recipe name: #{name}", model: "text-embedding-3-small").vectors
  end

  private

  def async_update
    ImageGeneratorJob.perform_later(self.id)
  end

end

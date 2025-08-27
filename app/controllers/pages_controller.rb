class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]
  # pages_controller.rb
def dashboard
  @recipes = Recipe.order(created_at: :desc).limit(20) # or current_user.recipes, etc.
  
  @top_recipes = Recipe
    .joins("LEFT JOIN votes ON votes.votable_id = recipes.id AND votes.votable_type = 'Recipe' AND votes.vote_flag = TRUE")
    .joins("LEFT JOIN favorites ON favorites.favoritable_id = recipes.id AND favorites.favoritable_type = 'Recipe' AND favorites.blocked = FALSE")
    .select("recipes.*, COUNT(DISTINCT votes.id) AS likes_count, COUNT(DISTINCT favorites.id) AS favs_count")
    .group("recipes.id")
    .order("likes_count DESC, favs_count DESC, recipes.created_at DESC")
    .limit(10)
end

  def home
  end
end

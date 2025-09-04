class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]
  # pages_controller.rb
def dashboard
  # --- RESULTS (filterable list) ---
  @recipes = Recipe.all

  # quick search by name
  @recipes = @recipes.where("recipes.name ILIKE ?", "%#{params[:query]}%") if params[:query].present?

  # filters
  @recipes = @recipes
               .with_ingredient(params[:ingredient])   # uses ingredients::text ILIKE (see note below)
               .by_cuisine(params[:cuisine])
               .by_diet(params[:diet])
               .by_method(params[:method])
               .by_meal_type(params[:meal_type])
               .by_time_lte(params[:max_minutes])
               .by_difficulty(params[:difficulty])
               .by_price_lte(params[:max_price_cents])
               .calories_lte(params[:max_kcal])

  @recipes = @recipes.in_season if params[:seasonal].present?
  @recipes = @recipes.with_tag(params[:mood]) if params[:mood].present?

  # sort (optional)
  @recipes =
    case params[:sort]
    when "newest"    then @recipes.order(created_at: :desc)
    when "oldest"    then @recipes.order(created_at: :asc)
    when "low_cal"   then @recipes.order(Arel.sql("COALESCE(calories_per_serving, 999999) ASC"))
    when "fastest"   then @recipes.order(Arel.sql("COALESCE(duration, 999999) ASC"))
    when "low_price" then @recipes.order(Arel.sql("COALESCE(price_per_serving_cents, 999999999) ASC"))
    else                  @recipes.order(created_at: :desc)
    end

  # cap / paginate (adjust to your liking)
  @recipes = @recipes.limit(20000) unless params[:page].present?
  @recipes = @recipes.page(params[:page]).per(24) if @recipes.respond_to?(:page)

  # --- TOP RECIPES (unchanged) ---
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

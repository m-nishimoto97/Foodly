class RecipesController < ApplicationController
  def new

  end

  def create
    ingredients = ["pork", "onions", "tofu", "sesame oil", "gochujang", "gochugaru", "garlic", "eggs"]
    time = 15
    prompt = <<-PROMPT
      Generate a recipe using only #{ingredients.join(',')} that take only #{time} minutes.
      Include the recipe's name, duration, diet (if present such as vegetarian or vegan), cuisine, and directions.
      Include it in json file
    PROMPT
  end

  def show
    @recipe = Recipe.find(params[:id])
  end

  def index
    @recipes = current_user.recipes
    @recipes = @recipes.where("name ILIKE ?", "%#{params[:query]}%") if params[:query].present?
  end

  def toggle_favorite
    @recipe = Recipe.find(params[:id])
    if current_user.favorited?(@recipe)
      current_user.unfavorite(@recipe)
    else
      current_user.favorite(@recipe)
    end
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @recipe }
    end
  end

  def like
    @recipe = Recipe.find(params[:id])

    if current_user.voted_up_on?(@recipe)
      @recipe.unliked_by(current_user)
    else
      @recipe.liked_by(current_user)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @recipe }
    end
  end
end

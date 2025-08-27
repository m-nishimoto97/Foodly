class RecipesController < ApplicationController
  def new

  end

  def create

  end

  def show
    @recipe = Recipe.find(params[:id])
  end

  def index
    @recipes = Recipe.all
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

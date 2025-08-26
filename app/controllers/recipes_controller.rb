class RecipesController < ApplicationController
  def new

  end

  def create

  end

  def show
    @recipe = Recipe.find(params[:id])
  end
end

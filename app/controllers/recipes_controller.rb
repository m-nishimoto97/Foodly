class RecipesController < ApplicationController
  def new
    @scan = Scan.find(params[:scan_id])
    @ingredients = ["tomato", "beef", "potato", "onions", "chicken", "pork"]
    @recipe = Recipe.new
    @durations = [15, 30, 45]
  end

  def create
  end

  def show
    @recipe = Recipe.find(params[:id])
  end
end

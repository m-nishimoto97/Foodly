class ReviewsController < ApplicationController
  def index
    @recipe = Recipe.find(params[:recipe_id])
    @reviews = @recipe.reviews.includes(:user).order(created_at: :desc)
    @review = @recipe.reviews.build

    render partial: "reviews/review_all", locals: { reviews: @reviews, review: @review, recipe: @recipe }
  end

  def create
    @recipe = Recipe.find(params[:recipe_id])
    @review = Review.new(review_params)
    @review.recipe = @recipe
    @review.user = current_user

    if @review.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @recipe }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("reviews_form",
          partial: "reviews/review_form", locals: { review: @recipe.reviews.build, recipe: @recipe }) }
      end
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment, :photo)
  end
end

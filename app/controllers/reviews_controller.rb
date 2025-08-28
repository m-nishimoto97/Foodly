class ReviewsController < ApplicationController
  def index
    @recipe = Recipe.find(params[:recipe_id])
    @reviews = @recipe.reviews.includes(:user)
    @review = Review.build

    render partial: "reviews/review_all", locals: { reviews: @reviews, review: @review }
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
      render partial: "reviews/review_all", status: :unprocessable_content
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end

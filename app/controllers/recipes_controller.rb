class RecipesController < ApplicationController
  def new
    @scan = Scan.find(params[:scan_id])
    @ingredients = @scan.ingredients
    @recipe = Recipe.new
    @durations = [15, 30, 45]
  end

  def create
    @scan = Scan.find(params[:scan_id])

    prompt = <<-PROMPT
      Generate two recipes using only #{@scan.ingredients.join(',')} that take only #{params['recipe']['duration']} minutes.
      Include the recipe's name, duration, diet (if present such as vegetarian or vegan), cuisine, and directions.
      Return in an array of recipe hashes in JSON format
    PROMPT

    response = RubyLLM.chat.ask(prompt)
    json_str = response.content.gsub(/```json\n|```/, '')
    # Raises an error if the AI response is weird
    begin
      recipes = JSON.parse(json_str)
    rescue JSON::ParserError => e
      flash[:alert] = "Failed to parse AI Response"
      redirect_to scan_path(@scan) and return
    end

    recipes.each do |recipe_data|
      @scan.recipes.create!(
        name: recipe_data["name"],
        duration: recipe_data["duration"],
        diet: recipe_data["diet"],
        cuisine: recipe_data["cuisine"],
        directions: recipe_data["directions"],
        ingredients: @scan.ingredients
      )
    end

    redirect_to scan_path(@scan)
  end

  def show
    @recipe = Recipe.find(params[:id])
    @ingredients = JSON.parse(@recipe.ingredients || "[]")
  end

  def index
    recipes = current_user.recipes
    favorites = current_user.all_favorited
    combined_ids = recipes.pluck(:id) + favorites.pluck(:id)
    @recipes = Recipe.where(id: combined_ids)
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

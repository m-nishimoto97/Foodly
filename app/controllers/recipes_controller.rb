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
    Generate exactly two recipes using only the following ingredients: #{@scan.ingredients.join(', ')}.
    Each recipe must take no more than #{params['recipe']['duration']} minutes to prepare.
    Take into account the user's preference: #{current_user.preference} and allergies: #{current_user.allergy}.

    For each recipe, provide the following keys in a JSON object:
    - "name": The recipe name should be real and be based off of real recipes and never do this: putting the ingredients together to makeup a new name (string)
    - "duration": Preparation time in minutes (integer)
    - "diet": Diet type if applicable (string, e.g., "vegetarian", "vegan"). If none, set as empty string.
    - "cuisine": Cuisine type (string)
    - "directions": A single string with **numbered** steps separated by '\\n'. Do not use HTML tags.
    Return the result as an array of exactly two recipe objects in **valid JSON only**.
    Do NOT include any text before or after the JSON. The output must be directly parsable.
    PROMPT

    response = RubyLLM.chat.ask(prompt)
    json_str = response.content.gsub(/```json\n|```/, '')
    # Raises an error if the AI response is weirdd
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
        directions: recipe_data["directions"]
      )
    end

    redirect_to scan_path(@scan)
  end

  def show
    @recipe = Recipe.find(params[:id])
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

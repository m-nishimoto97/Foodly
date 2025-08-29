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
You are a precise recipe formatter. Output valid JSON only. Do not wrap in code fences or add prose.

CONTEXT
- available_ingredients: <#{@scan.ingredients.join(', ')}>
- max_minutes: <#{params['recipe']['duration']}>
- user_preference: <#{current_user.preference}>
- allergies: <#{current_user.allergy}>

TASK
Create EXACTLY TWO real, sensible recipes that can be prepared within max_minutes using only the available_ingredients
(plus common pantry staples: water, salt, black pepper, sugar, neutral/olive oil, butter, vinegar, stock/broth, flour, baking powder, soy sauce, lemon juice). Respect user_preference and strictly avoid allergies.

OUTPUT FORMAT — JSON array with TWO objects. Each object MUST have ONLY these keys:
EXAMPLE SHAPE (structure only; do NOT copy values):
[
  {
    "name": "Spaghetti aglio e olio",
    "localized_name": "Espaguetis aglio e olio",
    "cuisine": "Italian",
    "diet": "",
    "duration": 15,
    "source_hint": "Wikipedia: Spaghetti aglio e olio",
    "directions": "1) ...\n2) ...\n3) ..."
  },
  {
    "name": "Tomato bruschetta",
    "localized_name": "Bruschetta de tomate",
    "cuisine": "Italian",
    "diet": "vegetarian",
    "duration": 12,
    "source_hint": "BBC Good Food: tomato bruschetta",
    "directions": "1) ...\n2) ...\n3) ..."
  }
]

STRICT HTML RULES
- ingredients_html MUST start with "<ul>" and end with "</ul>" and include only <li>…</li>.
- directions MUST start with "<ol>" and end with "</ol>" and include only <li>…</li>.
- summary_html MUST be exactly one "<p>…</p>".
- No attributes, classes, styles, Markdown, or extra text outside the specified tags.
- Keep ingredients_html ≤ 800 chars and directions (the HTML string) ≤ 1200 chars.

QUALITY RULES
- Avoid trivial dishes (e.g., plain toast or cucumber sandwich) unless ingredients strictly force it.
- Prefer straightforward mains or substantial sides that fit the time limit.
- Clear, concise sentences; avoid superlatives and storytelling.

RESPONSE
Return ONLY the JSON array with two recipe objects, nothing before or after.
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

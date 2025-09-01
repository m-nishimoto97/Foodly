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
- available_ingredients: <#{params['recipe']['name'].join(', ')}>
- max_minutes: <#{params['recipe']['duration']}>
- user_preference: <#{current_user.preference}>
- allergies: <#{current_user.allergy}>

TASK
Create EXACTLY TWO real, sensible recipes that can be prepared within max_minutes using only the available_ingredients
(plus common pantry staples: water, salt, black pepper, sugar, neutral/olive oil, butter, vinegar, stock/broth, flour, baking powder, soy sauce, lemon juice).
Respect user_preference and strictly avoid allergies.

INGREDIENT RULES (CRITICAL for UI scaling)
- Provide both:
  1) "ingredients": an OBJECT mapping ingredient names to amount strings
  2) "base_servings": an INTEGER (number of people the recipe serves, e.g., 2 or 4)
- Ingredient NAMES must be simple food items only (no adjectives at the start). Examples: "spaghetti", "garlic", "red onion", "banana".
- Amount strings must use ONE of these formats only (never mix notations):
  • Integer/decimal + unit: "2 cups", "2.5 cups", "250 g"
  • Mixed number: "1 1/2 cups"
  • Unicode fraction: "½ cup", "¼ cup", "¾ cup"
  • Range: "2-3 cups", "1-2 cloves"
  • Taste/approx: "to taste", "pinch"
- Never produce invalid strings like "1/2 /2 cup" or duplicated slashes.
- Optional short notes may go at the END in parentheses, e.g., "1 onion (finely chopped)".

HTML RULES (STRICT)
- "ingredients_html" MUST be exactly: "<ul>...<li>...</li>...</ul>" with ONLY <ul> and <li> tags. No attributes, classes, styles, or Markdown.
- "directions_html" MUST be exactly: "<ol>...<li>...</li>...</ol>" with ONLY <ol> and <li> tags. No attributes, classes, styles, or Markdown.
- "summary_html" MUST be exactly one "<p>…</p>".
- Keep ingredients_html ≤ 800 characters and directions_html ≤ 1200 characters. Be concise.

QUALITY RULES
- Avoid trivial dishes unless ingredients strictly force it.
- Prefer straightforward mains or substantial sides that fit the time limit.
- Sentences must be clear and instructional. No storytelling.

OUTPUT FORMAT
Return ONE JSON array with TWO objects. Each object MUST have ONLY these keys:

[
  {
    "name": string,
    "localized_name": string,
    "cuisine": string,
    "diet": string,
    "duration": integer,
    "source_hint": string,
    "base_servings": integer,
    "ingredients": { "spaghetti": "200 g", "garlic": "2 cloves", ... },
    "ingredients_html": "<ul>...</ul>",
    "directions": "1) ...\n2) ...\n3) ...",
    "directions_html": "<ol><li>...</li><li>...</li><li>...</li></ol>",
    "summary_html": "<p>...</p>"
  },
  {
    "name": "...",
    "localized_name": "...",
    "cuisine": "...",
    "diet": "...",
    "duration": ...,
    "source_hint": "...",
    "base_servings": ...,
    "ingredients": { "...": "..." },
    "ingredients_html": "<ul>...</ul>",
    "directions": "1) ...\n2) ...\n3) ...",
    "directions_html": "<ol><li>...</li><li>...</li><li>...</li></ol>",
    "summary_html": "<p>...</p>"
  }
]

VALIDATION
- Use only available_ingredients + the allowed staples.
- Keep duration ≤ max_minutes.
- Conform to user_preference and exclude allergies.
- Output MUST be valid JSON. Use ":" for JSON key/value separators (never "=>").
- Return ONLY the JSON array with two recipe objects, nothing before or after.



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
        directions: recipe_data["directions"],
        ingredients: recipe_data["ingredients"]
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

# app/controllers/recipes_controller.rb
class RecipesController < ApplicationController
  def new
    @scan = Scan.find(params[:scan_id])
    @ingredients = @scan.ingredients
    @recipe = Recipe.new
    @durations = [15, 30, 45]
  end

  def create
    @scan = Scan.find(params[:scan_id])

    # === BUILD PROMPT FOR RubyLLM ===
    prompt = <<-PROMPT

You are a precise recipe formatter. Output valid JSON only. Do not wrap in code fences or add prose.

CONTEXT
- available_ingredients: <#{params['recipe']['name'].join(', ')}>        # user ingredients
- max_minutes: <#{params['recipe']['duration']}>                           # time limit
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
    "ingredients_html": "<ul><li>...</li></ul>",
    "directions": "1) ...\n2) ...\n3) ...",
    "directions_html": "<ol><li>...</li><li>...</li><li>...</li></ol>",
    "summary_html": "<p>...</p>",
    "calories_per_serving": integer,       // realistic kcal per serving
    "method": string,                      // one of: "grilled", "baked", "steamed", "fried", "raw", "boiled"
    "meal_type": string,                   // one of: "breakfast", "lunch", "dinner", "snack"
    "difficulty": integer,                 // 1 easy, 2 medium, 3 hard
    "price_per_serving_cents": integer,    // estimated cost in cents per serving
    "mood": string                         // one of: "comfort food", "party food", "romantic dinner"
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
    "summary_html": "<p>...</p>",
    "calories_per_serving": ...,
    "method": "...",
    "meal_type": "...",
    "difficulty": ...,
    "price_per_serving_cents": ...,
    "mood": "..."
  }
]

VALIDATION
- Use only available_ingredients + the allowed staples.
- Keep duration ≤ max_minutes.
- Conform to user_preference and exclude allergies.
- Calories must be realistic for the dish and per serving.
- Difficulty must be 1 (easy), 2 (medium), or 3 (hard).
- Method must be chosen from the specified list.
- Meal type must be one of: breakfast, lunch, dinner, snack.
- Mood must be one of: comfort food, party food, romantic dinner.
- Price per serving must be an integer in cents (USD).
- Output MUST be valid JSON. Use ":" for JSON key/value separators (never "=>").
- Return ONLY the JSON array with TWO recipe objects, nothing before or after.

PROMPT

    response = RubyLLM.chat.ask(prompt)
    json_str = response.content.gsub(/```json\n|```/, '')

    begin
      recipes = JSON.parse(json_str)
    rescue JSON::ParserError
      flash[:alert] = "Failed to parse AI Response"
      redirect_to scan_path(@scan) and return
    end

    recipes.each do |rd|
      # --- calories fallback (kept as you had) ---
      calories = rd["calories_per_serving"]
      if calories.blank? && rd["ingredients"].present?
        calories = NutritionCalculator.new(
          rd["ingredients"],
          servings: rd["base_servings"] || 2
        ).call
      end

    attrs = {
      name:                     rd["name"],
      duration:                 rd["duration"],
      diet:                     rd["diet"],
      cuisine:                  rd["cuisine"],
      directions:               rd["directions"],
      ingredients:              rd["ingredients"],
      base_servings:            rd["base_servings"],
      calories_per_serving:     calories,
      method:                   rd["method"],
      meal_type:                rd["meal_type"],
      difficulty:               rd["difficulty"],
      price_per_serving_cents:  rd["price_per_serving_cents"],
      best_season_start:        rd["best_season_start"],
      best_season_end:          rd["best_season_end"]
    }.compact

    # Checks what recipes are similar
    recipe = @scan.recipes.new(attrs)
    recipe.set_embedding
    similar_recipes = Recipe.nearest_neighbors(:embedding, recipe.embedding, distance: "cosine").limit(3)
    threshold = 0.85
    is_duplicate = similar_recipes.any? do |r|
      distance = r.neighbor_distance
      (1 - distance) > threshold
    end

    if !is_duplicate
      recipe.save
    else
      @scan.recipes += Recipe.nearest_neighbors(:embedding, recipe.embedding, distance: "cosine").limit(1)
    end

    begin
        ImageGeneratorJob.perform_now(recipe.id)
      rescue => e
        Rails.logger.error("[Recipes#create] Image attach failed for recipe=#{recipe.id} #{e.class}: #{e.message}")
        # We don't raise; UI will just show the placeholder if something went wrong.
      end

    end
  redirect_to scan_path(@scan)
  end

  def filters
  end

  def show
    @recipe = Recipe.find(params[:id])
  end

  def index
    # Base: my recipes + my favorites
    owned_ids = current_user.recipes.select(:id)

    favorited_ids =
      if current_user.respond_to?(:favorited)
        current_user.favorited(Recipe).select(:id)
      elsif current_user.respond_to?(:favorited_by_type)
        Recipe.where(id: current_user.favorited_by_type('Recipe').pluck(:id)).select(:id)
      else
        Recipe.none.select(:id)
      end

    @recipes = Recipe.where(id: owned_ids).or(Recipe.where(id: favorited_ids))

    # quick search by name
    @recipes = @recipes.where("recipes.name ILIKE ?", "%#{params[:query]}%") if params[:query].present?

    # filters
    @recipes = @recipes
                 .with_ingredient(params[:ingredient])
                 .by_cuisine(params[:cuisine])
                 .by_diet(params[:diet])
                 .by_method(params[:method])
                 .by_meal_type(params[:meal_type])
                 .by_time_lte(params[:max_minutes])
                 .by_difficulty(params[:difficulty])
                 .by_price_lte(params[:max_price_cents])
                 .calories_lte(params[:max_kcal])

    @recipes = @recipes.in_season if params[:seasonal].present?
    @recipes = @recipes.with_tag(params[:mood]) if params[:mood].present?

    # sorting (optional)
    @recipes = case params[:sort]
               when "newest"    then @recipes.order(created_at: :desc)
               when "oldest"    then @recipes.order(created_at: :asc)
               when "low_cal"   then @recipes.order(Arel.sql("COALESCE(calories_per_serving, 999999) ASC"))
               when "low_price" then @recipes.order(Arel.sql("COALESCE(price_per_serving_cents, 999999999) ASC"))
               when "fastest"   then @recipes.order(Arel.sql("COALESCE(duration, 999999) ASC"))
               else @recipes.order(created_at: :desc)
               end

    @recipes = @recipes.includes(:tags) if Recipe.reflect_on_association(:tags)
    @recipes = @recipes.page(params[:page]).per(24) if @recipes.respond_to?(:page)
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

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
You are a precise recipe formatter.
Output valid JSON only — no code fences, no prose, no Markdown.
Your first character MUST be “[” and your last character MUST be “]”.

CONTEXT
- available_ingredients: <#{params['recipe']['name'].join(', ')}>
- max_minutes: <#{params['recipe']['duration']}>
- user_preference: <#{current_user.preference}>
- allergies: <#{current_user.allergy}>

DEFINITIONS
- ALLOWED_STAPLES (usable implicitly, NEVER listed in "ingredients"): water, salt, black pepper, sugar, neutral oil, olive oil, butter, vinegar, stock/broth, flour, baking powder, soy sauce, lemon juice
- PANTRY_SET = case-insensitive set of ALLOWED_STAPLES keywords (e.g., "water", "salt", "pepper", "sugar", "oil", "butter", "vinegar", "stock", "broth", "flour", "baking powder", "soy sauce", "lemon juice")

TASK
Generate EXACTLY TWO realistic, distinct recipes that:
- Have duration ≤ max_minutes
- Use ONLY: available_ingredients + ALLOWED_STAPLES
- Strictly respect user_preference and exclude allergies

INGREDIENT RULES (IMPORTANT)
- Provide BOTH fields:
  • "ingredients": OBJECT mapping { simple_name → amount_string }
  • "base_servings": INTEGER (e.g., 2 or 4)
- Ingredient NAMES must be simple food items only (no leading adjectives/brands). Examples: "spaghetti", "garlic", "tomato".
- DO NOT include any PANTRY_SET item in "ingredients" even if it appears in available_ingredients (use implicitly).
- Deduplicate keys case-insensitively (normalize singular/plural; e.g., keep "tomatoes").
- Amount string formats allowed ONLY:
  "200 g", "2 cups", "1 1/2 cups", "1/2 cup", "2-3 cups", "1-2 cloves", "to taste", "pinch"
  Optional short note at END in parentheses, e.g., "1 onion (chopped)".
  Never mix notations or include slashes like "200g/1 cup".
- Keep "ingredients" ≤ 20 items. Omit pantry staples entirely.

HTML RULES
- "ingredients_html" = one `<ul class="list-unstyled"> ... </ul>` with items like:
  `<li class="d-flex align-items-center"><span class="me-2 badge bg-secondary">AMOUNT</span><span>INGREDIENT_NAME</span></li>`
  (Do NOT include pantry staples.)
- "directions_html" = one ordered list using Bootstrap:
  `<ol class="list-group list-group-numbered">`
    Each step:
    `<li class="list-group-item d-flex justify-content-between align-items-start">
       <div class="ms-2 me-auto">
         <div class="fw-bold">STEP_TITLE</div>
         STEP_BODY (optional)
       </div>
       <span class="badge bg-primary rounded-pill">~N min</span>
     </li>`
  STEP_TITLE = 2–5 words, imperative (e.g., "Prep aromatics", "Sear & simmer").
  STEP_BODY = 1–2 concise sentences that ADD details not in the title.
  If STEP_BODY would duplicate the title (case-insensitive, ignoring punctuation/spacing), OMIT the body and keep only the title.
- "summary_html" = single `<p class="text-muted mb-0">…</p>`.
- Hard caps: ingredients_html ≤ 800 chars; directions_html ≤ 1200 chars; summary_html ≤ 300 chars.

QUALITY RULES
- Prefer mains or substantial sides unless ingredients force otherwise.
- Vary techniques/flavors between the two recipes.
- Use clear, instructional language (no storytelling).
- Do not invent unavailable ingredients; everything outside PANTRY_SET must come from available_ingredients.

OUTPUT FORMAT
Return ONE JSON array with TWO objects. Each object MUST contain ONLY:

{
  "name": string,
  "localized_name": string,
  "cuisine": string,
  "diet": string,
  "duration": integer,
  "source_hint": string,
  "base_servings": integer,
  "ingredients": { "spaghetti": "200 g", "garlic": "2 cloves (minced)", ... },
  "ingredients_html": "<ul class=\"list-unstyled\"><li class=\"d-flex align-items-center\"><span class=\"me-2 badge bg-secondary\">200 g</span><span>spaghetti</span></li>...</ul>",
  "directions": "1) ...\n2) ...\n3) ...",
  "directions_html": "<ol class=\"list-group list-group-numbered\"><li class=\"list-group-item d-flex justify-content-between align-items-start\"><div class=\"ms-2 me-auto\"><div class=\"fw-bold\">STEP_TITLE</div>STEP_BODY</div><span class=\"badge bg-primary rounded-pill\">~N min</span></li>...</ol>",
  "summary_html": "<p class=\"text-muted mb-0\">...</p>",
  "calories_per_serving": integer,
  "method": "grilled|baked|steamed|fried|raw|boiled",
  "meal_type": "breakfast|lunch|dinner|snack",
  "difficulty": 1|2|3,
  "price_per_serving_cents": integer,
  "mood": "comfort food|party food|romantic dinner"
}

ENUM RULES & VALIDATION
- "method" ∈ {grilled, baked, steamed, fried, raw, boiled}
- "meal_type" ∈ {breakfast, lunch, dinner, snack}
- "difficulty" ∈ {1,2,3}
- "duration" ≤ max_minutes
- "price_per_serving_cents" = non-negative integer
- "calories_per_serving" realistic (150–900)
- NO pantry staples in "ingredients"/"ingredients_html"
- NO duplicate ingredient keys (case-insensitive)
- All fields present; no extra keys

SELF-CHECK (MANDATORY)
1) Exactly TWO recipe objects in a single JSON array.
2) Valid JSON (no trailing commas; all keys/strings quoted).
3) Every non-pantry ingredient appears in available_ingredients (case-insensitive; simple singular/plural normalization).
4) "ingredients" and "ingredients_html" list the SAME non-pantry items/amounts.
5) "directions_html" follows the exact structure and length caps.
6) No step has a body that duplicates its title (case-insensitive; punctuation/spacing ignored).
7) Output starts with “[” and ends with “]”. Output nothing else.

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
    similar_recipes = Recipe.nearest_neighbors(:embedding, recipe.embedding, distance: "cosine").limit(2)
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
        ImageGeneratorJob.perform_later(recipe.id)
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

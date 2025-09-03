class SchedulesController < ApplicationController
  def index
    @schedule = current_user.schedules.new
    @schedules = current_user.schedules.includes(:recipe)
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today

    @recipes = if params[:query].present?
                current_user.recipes.where("name ILIKE ?", "%#{params[:query]}%")
              else
                current_user.recipes
              end
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @schedule = current_user.schedules.new(schedule_params)
    @recipes = current_user.recipes
    if @schedule.save
      @schedules = current_user.schedules.includes(:recipe)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to schedules_path(start_date: @schedule.date.beginning_of_month), status: :see_other }
      end
    else
      render :index, status: :unprocessable_content
    end
  end

  def generate_ai
    days = if params[:btnradio] == "other"
      params[:custom_period]
    else
      params[:period]
    end
    prompt = prompt(params[:start_date], days.to_i)
    puts prompt
    response = RubyLLM.chat.ask(prompt)
    json_str = response.content.gsub(/```json\n|```/, '')

    begin
      recipes = JSON.parse(json_str)
      rescue JSON::ParserError
        flash[:alert] = "Failed to parse AI Response"
        redirect_to schedules_path and return
      end

      recipes.each do |rd|
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

      @scan = Scan.create!(user: current_user)
      recipe = @scan.recipes.new(attrs)
      recipe.set_embedding
      similar_recipes = Recipe.nearest_neighbors(:embedding, recipe.embedding, distance: "cosine").limit(5)
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

      attrsSchedule = {
        date: rd["date"],
        recipe_id: @scan.recipes.last.id
      }

      last_schedule = current_user.schedules.create!(attrsSchedule)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to schedules_path(start_date: last_schedule.date.beginning_of_month), status: :see_other }
    end
  end


  private

  def schedule_params
    params.require(:schedule).permit(:date, :recipe_id)
  end

  def prompt(start_date, days)
    prompt = <<-PROMPT

    You are a professional cooker and precise recipe formatter. Output valid JSON only. Do not wrap in code fences or add prose.

    CONTEXT
    - user_preference: <#{current_user.preference}>
    - allergies: <#{current_user.allergy}>

    TASK
    Create real world recipes for exactly #{days} days (lunch and dinner) starting at #{start_date}, using common ingredients and pantry from daily cooking.
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
    - Prefer straightforward mains or substantial sides.
    - Sentences must be clear and instructional. No storytelling.

    OUTPUT FORMAT
    Return ONE JSON array with the recipes as objects. Each object MUST have ONLY these keys:

    [
      {
        "date": date,
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
        "date": "yyyy-MM-dd",
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
    - Conform to user_preference and exclude allergies.
    - Calories must be realistic for the dish and per serving.
    - Difficulty must be 1 (easy), 2 (medium), or 3 (hard).
    - Method must be chosen from the specified list.
    - Meal type must be one of: breakfast, lunch, dinner.
    - Mood must be one of: comfort food, party food, romantic dinner.
    - Price per serving must be an integer in cents (USD).
    - Output MUST be valid JSON. Use ":" for JSON key/value separators (never "=>").
    - Return ONLY the JSON array with #{days * 2} recipe objects, nothing before or after.

    PROMPT
  end
end

# app/services/nutrition_calculator.rb
class NutritionCalculator
  KCAL = {
    "banana" => 105, "egg" => 70,
    "milk" => 60,          # per 100 ml
    "flour" => 364,        # per 100 g
    "sugar" => 387,        # per 100 g
    "butter" => 717,       # per 100 g
    "olive oil" => 884     # per 100 g (~90 ml)
  }

  def initialize(ingredients_hash, servings: 2)
    @ingredients = ingredients_hash || {}
    @servings    = [servings.to_i, 1].max
  end

  def call
    total = 0.0
    @ingredients.each do |name, amount|
      total += estimate_kcal(name.to_s.downcase, amount.to_s.downcase)
    end
    (total / @servings).round
  end

  private

  def estimate_kcal(name, amount)
    base = KCAL.keys.find { |k| name.include?(k) }
    return 0 unless base

    qty = in_100g_or_unit(base, amount)
    return KCAL["egg"] * qty if base == "egg"
    KCAL[base] * qty
  end

  def in_100g_or_unit(base, amount)
    if amount =~ /(\d+(?:\.\d+)?)(?:\s+|)(cup|cups|tbsp|tbsps|tsp|tsps|g|gram|grams|ml|l|egg|eggs)?/
      num  = $1.to_f
      unit = ($2 || "").downcase

      case unit
      when "g","gram","grams" then num / 100.0
      when "ml"               then num / 100.0
      when "l"                then (num * 1000.0) / 100.0
      when "cup","cups"       then base == "milk" ? (num * 240.0 / 100.0) : num
      when "tbsp","tbsps"     then (num * 15.0 / 100.0)
      when "tsp","tsps"       then (num * 5.0 / 100.0)
      when "egg","eggs"       then num
      else                         num
      end
    else
      1.0
    end
  end
end

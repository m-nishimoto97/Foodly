# db/seeds.rb — Mega seed for Foodly

# ---------- Safe Faker loader (optional) ----------
begin
  require "faker"
  USING_FAKER = true
rescue LoadError
  USING_FAKER = false
  puts "[seeds] Faker not installed — using built-in generators."
end

require "securerandom"

module SeedGen
  FIRST = %w[Alex Sam Riley Jordan Casey Taylor Jamie Robin Morgan Quinn Rafa
             Diego Lucia Sofia Kai Emi Ren Mei Leo Noah Ava Mia Liam Emma].freeze
  LAST  = %w[Pradillo Kim Lee Garcia Silva Brown Chan Ito Suzuki Rossi Müller
             Dubois Smith Lopez Park Nguyen Cohen Costa].freeze
  DOMS  = %w[@example.com @mail.com @foodly.test @demo.io @sample.net].freeze

  module_function
  def username(i=nil)
    if USING_FAKER
      Faker::Internet.username(specifier: "#{Faker::Name.first_name} #{Faker::Name.last_name}", separators: %w[_ .])[0,30]
    else
      base = "#{FIRST.sample}_#{LAST.sample}".downcase
      (i ? "#{base}_#{i}" : "#{base}_#{SecureRandom.hex(2)}")[0,30]
    end
  end

  def email
    USING_FAKER ? Faker::Internet.unique.email : "user-#{SecureRandom.hex(4)}#{DOMS.sample}"
  end

  def sentence
    return "#{Faker::Food.description}." if USING_FAKER
    %w[Great Delicious Balanced Easy Weeknight Comforting Spicy].sample + " recipe."
  end
end

# ---------- Sizes (tunable via ENV) ----------
SEED_RANDOM_SEED   = (ENV["SEED_SEED"] || 42).to_i
USERS_COUNT        = (ENV["SEED_USERS"] || 120).to_i
SCANS_PER_USER_MIN = (ENV["SEED_SCANS_MIN"] || 1).to_i
SCANS_PER_USER_MAX = (ENV["SEED_SCANS_MAX"] || 2).to_i
RECIPES_PER_SCAN_MIN = (ENV["SEED_REC_MIN"] || 2).to_i
RECIPES_PER_SCAN_MAX = (ENV["SEED_REC_MAX"] || 5).to_i
EXTRA_RECIPES      = (ENV["SEED_EXTRA_RECIPES"] || 100).to_i
REVIEWS_COUNT      = (ENV["SEED_REVIEWS"] || 700).to_i
FAVORITES_MIN      = (ENV["SEED_FAV_MIN"] || 3).to_i
FAVORITES_MAX      = (ENV["SEED_FAV_MAX"] || 10).to_i
LIKES_MIN          = (ENV["SEED_LIKE_MIN"] || 5).to_i
LIKES_MAX          = (ENV["SEED_LIKE_MAX"] || 20).to_i

srand(SEED_RANDOM_SEED)
Faker::Config.random = Random.new(SEED_RANDOM_SEED) if USING_FAKER

# ---------- Vocab ----------
CUISINES = %w[
  Italian Japanese Indian Mexican Thai Greek Middle\ Eastern Spanish French
  American Chinese Korean Vietnamese Peruvian Lebanese Turkish Caribbean
].freeze

DIETS = %w[omnivore vegetarian vegan pescatarian gluten-free dairy-free high\ protein].freeze

ALLERGIES = [nil, nil, nil, "nuts", "seafood", "gluten", "dairy", "eggs", "soy", "sesame"].freeze

PANTRY = %w[
  garlic onion tomato potato carrot bell_pepper chili_flakes basil parsley cilantro
  olive_oil butter soy_sauce miso ginger lemon lime vinegar sugar salt pepper paprika
  cumin coriander turmeric curry_powder garam_masala coconut_milk tomato_paste dashi
  tofu chicken_thighs beef_minced pork_belly egg rice pasta udon rice_noodles
  beans chickpeas lentils quinoa broccoli spinach kale cucumber feta olives oregano
  avocado cheddar mozzarella parmesan tortilla pita naan yogurt tahini sesame_oil
  fish_sauce shrimp salmon tuna nori seaweed green_onion scallions mirin sake
].freeze

CANONICAL_RECIPES = [
  "Spaghetti Aglio e Olio","Chicken Teriyaki Bowl","Vegan Lentil Curry","Greek Salad","Beef Tacos",
  "Miso Soup","Pad Thai","Shakshuka","Margherita Pizza","Bibimbap","Pho Bo","Ceviche",
  "Falafel with Tahini","Hummus Bowl","Ratatouille","Butter Chicken","Chana Masala",
  "Dal Tadka","Paneer Butter Masala","Paella Mixta","Gazpacho","Ramen Shoyu","Okonomiyaki",
  "Tortilla Española","Burrito Bowl","Salmon Poke","Veggie Gyoza","Tacos al Pastor",
  "Tteokbokki","Katsu Curry","Yakimeshi","Couscous Veggie","Pollo al Limón",
  "Minestrone","Roasted Tomato Soup","Arroz Chaufa","Arroz con Pollo","Lomo Saltado",
  "Tonkatsu","Udon Tempura","Enchiladas Verdes","Mapo Tofu","Banh Mi Bowl"
].freeze

DIRECTIONS_TEMPLATES = [
  "Prep ingredients. Heat %{fat}. Sauté %{aromatics}. Add %{main}. Season %{spices}. Simmer %{time} min. Finish with %{finish}.",
  "Boil %{carb}. In pan: %{fat} + %{aromatics} → %{main}. Deglaze with %{liquid}. Toss %{carb}. Top with %{finish}.",
  "Whisk sauce (%{sauce}). Stir-fry %{main} + veggies. Add %{carb}. Pour sauce, cook %{time} min. Serve with %{finish}.",
  "Marinate %{main} (%{spices}, %{acid}). Sear %{time} min/side. Serve over %{carb}. Garnish %{finish}."
].freeze

FATS = %w[olive_oil butter ghee sesame_oil neutral_oil].freeze
AROMATICS = %w[garlic onion ginger scallions].freeze
SPICES = %w[salt pepper paprika cumin coriander turmeric chili_flakes oregano].freeze
LIQUIDS = %w[stock water coconut_milk tomato_sauce dashi soy_sauce].freeze
CARBS = %w[rice pasta udon rice_noodles quinoa couscous tortillas].freeze
FINISHERS = %w[basil parsley cilantro lemon_zest lime_juice sesame_seeds parmesan].freeze

def pick(list, n = 1) = list.sample(n)

def sentence_for_directions
  template = DIRECTIONS_TEMPLATES.sample
  template % {
    fat: FATS.sample,
    aromatics: pick(AROMATICS, 2).join(", "),
    main: pick(%w[tofu chicken thighs beef shrimp mushrooms eggplant chickpeas lentils], 1).first,
    spices: pick(SPICES, 3).join(", "),
    time: rand(8..25),
    liquid: LIQUIDS.sample,
    carb: CARBS.sample,
    sauce: [LIQUIDS.sample, SPICES.sample, "sugar", "vinegar"].join(", "),
    acid: pick(%w[lemon_juice lime_juice vinegar], 1).first,
    finish: FINISHERS.sample
  }
end

def random_ingredients = pick(PANTRY, rand(5..12))
def gen_username(i=nil) = SeedGen.username(i)
def gen_email = SeedGen.email
def gen_comment = SeedGen.sentence

# ---------- Reset ----------
puts "== Resetting DB =="
Favorite.delete_all                 if defined?(Favorite)
ActsAsVotable::Vote.delete_all      if defined?(ActsAsVotable::Vote)
Review.delete_all                   if defined?(Review)
Recipe.delete_all                   if defined?(Recipe)
Scan.delete_all                     if defined?(Scan)
User.delete_all                     if defined?(User)

%w[users scans recipes reviews votes favorites].each do |t|
  next unless ActiveRecord::Base.connection.table_exists?(t)
  ActiveRecord::Base.connection.reset_pk_sequence!(t) rescue nil
end

# ---------- Users ----------
puts "== Creating Users =="
users = []
USERS_COUNT.times do |i|
  users << User.create!(
    username: gen_username(i),
    email: gen_email,
    password: "123456",
    allergy: ALLERGIES.sample,
    preference: DIETS.sample
  )
end

admin = User.create!(username: "admin", email: "admin@example.com", password: "123456", preference: "omnivore")
demo  = User.create!(username: "demo",  email: "demo@example.com",  password: "123456", preference: "vegetarian")
users += [admin, demo]
puts "Users: #{users.size}"

# ---------- Scans & Recipes ----------
puts "== Creating Scans & Recipes (per scan) =="
recipes = []

users.each do |u|
  rand(SCANS_PER_USER_MIN..SCANS_PER_USER_MAX).times do
    scan = u.scans.create!(ingredients: random_ingredients)
    rand(RECIPES_PER_SCAN_MIN..RECIPES_PER_SCAN_MAX).times do
      name = CANONICAL_RECIPES.sample
      recipes << scan.recipes.create!(
        name: name,
        directions: sentence_for_directions,
        duration: rand(10..60),
        cuisine: CUISINES.sample,
        diet: DIETS.sample,
        ingredients: pick(PANTRY, rand(4..10)).join(", ")
      )
    end
  end
end

puts "Recipes so far: #{recipes.size}"

# ---------- Extra global recipes ----------
puts "== Creating Extra Global Recipes =="
EXTRA_RECIPES.times do
  owner = users.sample
  scan  = owner.scans.sample || owner.scans.create!(ingredients: random_ingredients)
  recipes << scan.recipes.create!(
    name: CANONICAL_RECIPES.sample,
    directions: sentence_for_directions,
    duration: rand(10..60),
    cuisine: CUISINES.sample,
    diet: DIETS.sample,
    ingredients: pick(PANTRY, rand(4..10)).join(", ")
  )
end

# De-duplication (allow 2 duplicates, suffix after that)
name_counts = Hash.new(0)
recipes.each do |r|
  name_counts[r.name] += 1
  r.update!(name: "#{r.name} (##{name_counts[r.name]})") if name_counts[r.name] > 2
end

puts "Total Recipes: #{recipes.size}"

# ---------- Reviews ----------
puts "== Creating Reviews =="
REVIEWS_COUNT.times do
  Review.create!(
    user: users.sample,
    recipe: recipes.sample,
    rating: rand(3..5),
    comment: gen_comment
  )
end
puts "Reviews: #{Review.count}"

# ---------- Favorites ----------
if defined?(Favorite) && users.first.respond_to?(:favorite)
  puts "== Creating Favorites =="
  users.each do |u|
    pick(recipes, rand(FAVORITES_MIN..FAVORITES_MAX)).each { |r| u.favorite(r) rescue nil }
  end
  puts "Favorites: #{Favorite.count}"
else
  puts "Favorites gem not detected — skipping."
end

# ---------- Likes ----------
if defined?(ActsAsVotable) && recipes.first.respond_to?(:liked_by)
  puts "== Creating Likes =="
  users.each do |u|
    pick(recipes, rand(LIKES_MIN..LIKES_MAX)).each { |r| r.liked_by(u) rescue nil }
  end
  like_count =
    if defined?(ActsAsVotable::Vote) then ActsAsVotable::Vote.count
    elsif ActiveRecord::Base.connection.table_exists?(:votes) then Vote.count rescue 0
    else 0 end
  puts "Votes: #{like_count}"
else
  puts "acts_as_votable not detected — skipping likes."
end

# ---------- Summary ----------
puts "== DONE =="
puts "Users:    #{User.count}"
puts "Scans:    #{Scan.count}"
puts "Recipes:  #{Recipe.count}"
puts "Reviews:  #{Review.count}"
puts "Favorites: #{Favorite.count}" if defined?(Favorite)
if defined?(ActsAsVotable::Vote)
  puts "Votes:    #{ActsAsVotable::Vote.count}"
elsif ActiveRecord::Base.connection.table_exists?(:votes)
  puts "Votes:    #{Vote.count rescue 'n/a'}"
end

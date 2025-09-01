# db/seeds.rb
# Mega seeds for Foodly — users, scans, recipes, reviews, votes, favorites
# -------------------------------------------------------------

require "faker"
require "securerandom"

Rails.logger.silence do
  puts "== Resetting DB =="
  # Delete children first to respect FKs when not using dependent: :destroy
  Favorite.delete_all   if defined?(Favorite)
  ActsAsVotable::Vote.delete_all if defined?(ActsAsVotable::Vote)
  Review.delete_all     if defined?(Review)
  Recipe.delete_all     if defined?(Recipe)
  Scan.delete_all       if defined?(Scan)
  User.delete_all       if defined?(User)

  # Optional: reset PK sequences (PG only)
  %w[users scans recipes reviews votes favorites].each do |table|
    next unless ActiveRecord::Base.connection.table_exists?(table)
    ActiveRecord::Base.connection.reset_pk_sequence!(table) rescue nil
  end

  # -------------------------
  # CONFIG (tune as you like)
  # -------------------------
  SEED_RANDOM_SEED   = 42          # deterministic runs
  USERS_COUNT        = 150
  SCANS_PER_USER     = 1..2
  RECIPES_PER_SCAN   = 2..5        # typical per scan
  EXTRA_RECIPES      = 120         # additional global recipes not tied to a scan’s pantry
  REVIEWS_COUNT      = 800
  FAVORITES_PER_USER = 3..10
  LIKES_PER_USER     = 5..20       # acts_as_votable votes (like-only)

  srand(SEED_RANDOM_SEED)
  Faker::Config.random = Random.new(SEED_RANDOM_SEED)

  # -------------------------
  # TAXONOMIES / VOCAB
  # -------------------------
  CUISINES = %w[
    Italian Japanese Indian Mexican Thai Greek Middle\ Eastern Spanish French
    American Chinese Korean Vietnamese Peruvian Lebanese Turkish Caribbean
  ]

  DIETS = %w[omnivore vegetarian vegan pescatarian gluten-free dairy-free high\ protein]

  ALLERGIES = [
    nil, nil, nil, "nuts", "seafood", "gluten", "dairy", "eggs", "soy", "sesame"
  ]

  # Pantry items for generating scans and ingredients
  PANTRY = %w[
    garlic onion tomato potato carrot bell_pepper chili_flakes basil parsley cilantro
    olive_oil butter soy_sauce miso ginger lemon lime vinegar sugar salt pepper paprika
    cumin coriander turmeric curry_powder garam_masala coconut_milk tomato_paste dashi
    tofu chicken_beast chicken_thigh beef_minced pork_belly egg rice pasta udon rice_noodles
    beans chickpeas lentils quinoa broccoli spinach kale cucumber feta olives oregano
    avocado cheddar mozzarella parmesan tortilla pita naan yogurt tahini sesame_oil
    fish_sauce shrimp salmon tuna nori seaweed
  ]

  # Real-ish recipe names (curated + Faker fallback)
  CANONICAL_RECIPES = [
    "Spaghetti Aglio e Olio",
    "Chicken Teriyaki Bowl",
    "Vegan Lentil Curry",
    "Greek Salad",
    "Beef Tacos",
    "Miso Soup",
    "Pad Thai",
    "Shakshuka",
    "Margherita Pizza",
    "Bibimbap",
    "Pho Bo",
    "Arepas Reina Pepiada",
    "Ceviche Clásico",
    "Falafel con Tahini",
    "Hummus Bowl",
    "Ratatouille",
    "Butter Chicken",
    "Tikka Masala de Garbanzos",
    "Paella Mixta",
    "Gazpacho",
    "Ramen Shoyu",
    "Okonomiyaki",
    "Tortilla de Patatas",
    "Burrito Bowl",
    "Poke de Salmón",
    "Gyozas de Verduras",
    "Tostadas de Tinga",
    "Tacos al Pastor",
    "Empanadas Criollas",
    "Tteokbokki",
    "Katsu Curry",
    "Yakimeshi",
    "Couscous con Verduras",
    "Bulgur con Menta y Limón",
    "Pollo al Limón",
    "Ensalada César",
    "Minestrone",
    "Sopa de Tomate Asado",
    "Arroz Chaufa",
    "Arroz con Pollo",
    "Lomo Saltado",
    "Tonkatsu",
    "Udon con Tempura",
    "Sushi California",
    "Nigiri Variado",
    "Enchiladas Verdes",
    "Chana Masala",
    "Dal Tadka",
    "Paneer Butter Masala"
  ]

  DIRECTIONS_TEMPLATES = [
    "Prep all ingredients. Heat pan with %{fat}. Sauté aromatics (%{aromatics}). Add %{main}. Season with %{spices}. Simmer %{time} min. Finish with %{finish}.",
    "Bring pot of water to boil for %{carb}. In skillet, add %{fat}, then %{aromatics}. Stir in %{main}. Deglaze with %{liquid}. Toss %{carb}. Top with %{finish}.",
    "Whisk sauce: %{sauce}. Stir-fry %{main} over high heat. Add veggies and %{carb}. Pour sauce, cook %{time} min. Serve hot with %{finish}.",
    "Marinate %{main} with %{spices} and %{acid}. Grill or pan-sear %{time} min each side. Serve over %{carb} and garnish with %{finish}."
  ]

  FATS = %w[olive_oil butter ghee sesame_oil neutral_oil]
  AROMATICS = %w[garlic onion ginger scallions celery]
  SPICES = %w[salt pepper paprika cumin coriander turmeric chili_flakes oregano]
  LIQUIDS = %w[stock water coconut_milk tomato_sauce dashi soy_sauce]
  CARBS = %w[rice pasta udon rice_noodles quinoa couscous tortillas]
  FINISHERS = %w[basil parsley cilantro lemon_zest lime_juice sesame_seeds parmesan]

  # Helpers
  def pick(list, n = 1)
    list.sample(n)
  end

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

  def random_ingredients
    pick(PANTRY, rand(5..12))
  end

  # -------------------------
  # SEEDING
  # -------------------------
  puts "== Creating Users =="
  users = []
  USERS_COUNT.times do |i|
    username = "#{Faker::Internet.username(specifier: "#{Faker::Name.first_name} #{Faker::Name.last_name}", separators: %w[_ .])}-#{i}"
    users << User.create!(
      username: username.first(30),
      email: Faker::Internet.unique.email,
      password: "123456",
      allergy: ALLERGIES.sample,
      preference: DIETS.sample
    )
  end

  # Optional admin/test users
  admin = User.create!(username: "admin", email: "admin@example.com", password: "123456", preference: "omnivore")
  demo  = User.create!(username: "demo",  email: "demo@example.com",  password: "123456", preference: "vegetarian")
  users += [admin, demo]

  puts "Users: #{users.size}"

  puts "== Creating Scans & Recipes (by scan) =="
  recipes = []

  users.each do |u|
    rand(SCANS_PER_USER).each do
      scan = u.scans.create!(ingredients: random_ingredients)

      # A few recipes linked to this scan
      rand(RECIPES_PER_SCAN).each do
        name = (CANONICAL_RECIPES.sample || Faker::Food.dish)
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

  puts "Recipes so far (from scans): #{recipes.size}"

  puts "== Creating Extra Global Recipes (not tied to pantry logic) =="
  EXTRA_RECIPES.times do
    base_name = CANONICAL_RECIPES.sample || Faker::Food.dish
    owner_scan = users.sample.scans.sample || users.sample.scans.create!(ingredients: random_ingredients)
    recipes << owner_scan.recipes.create!(
      name: base_name,
      directions: sentence_for_directions,
      duration: rand(10..60),
      cuisine: CUISINES.sample,
      diet: DIETS.sample,
      ingredients: pick(PANTRY, rand(4..10)).join(", ")
    )
  end

  # De-duplicate recipe names lightly by appending suffix when collisions are too many
  name_counts = Hash.new(0)
  recipes.each do |r|
    name_counts[r.name] += 1
    r.update!(name: "#{r.name} (##{name_counts[r.name]})") if name_counts[r.name] > 2
  end

  puts "Total Recipes: #{recipes.size}"

  puts "== Creating Reviews =="
  review_bodies = [
    "So good and easy to follow!",
    "Solid weeknight dinner. Will make again.",
    "Needed more salt for my taste.",
    "Perfect balance of flavors.",
    "Kid approved!",
    "Took longer than stated, but worth it.",
    "Sauce slapped fr.",
    "Five stars if it had more heat.",
    "Obsessed with this recipe.",
    "Meal-prep friendly and cheap."
  ]

  REVIEWS_COUNT.times do
    user = users.sample
    recipe = recipes.sample
    Review.create!(
      user: user,
      recipe: recipe,
      rating: rand(3..5),
      comment: "#{review_bodies.sample} #{Faker::Food.description}."
    )
  end

  puts "Reviews: #{Review.count}"

  # -------------------------
  # Favorites (if using favorites gem)
  # -------------------------
  if defined?(Favorite)
    puts "== Creating Favorites =="
    users.each do |u|
      pick(recipes, rand(FAVORITES_PER_USER)).each do |r|
        u.favorite(r) rescue nil
      end
    end
    puts "Favorites: #{Favorite.count}"
  else
    puts "Favorites gem not detected — skipping."
  end

  # -------------------------
  # Likes/Votes (acts_as_votable)
  # -------------------------
  if defined?(ActsAsVotable)
    puts "== Creating Likes (votes) =="
    users.each do |u|
      pick(recipes, rand(LIKES_PER_USER)).each do |r|
        r.liked_by(u) rescue nil
      end
    end
    votes_count = if defined?(ActsAsVotable::Vote)
                    ActsAsVotable::Vote.count
                  else
                    Vote.count rescue 0
                  end
    puts "Votes: #{votes_count}"
  else
    puts "acts_as_votable not detected — skipping likes."
  end

  # -------------------------
  # (Optional) Attach placeholder photos via ActiveStorage
  # -------------------------
  if Recipe.new.respond_to?(:photos)
    puts "== Attaching placeholder photos =="
    require "open-uri"

    recipes.sample([recipes.size, 120].min).each do |r|
      # Use a generic placeholder; swap with your CDN if desired
      url = "https://picsum.photos/seed/#{SecureRandom.hex(4)}/800/600"
      file = URI.open(url) rescue nil
      next unless file
      r.photos.attach(io: file, filename: "recipe-#{r.id}.jpg", content_type: "image/jpeg") rescue nil
    end
    puts "Photos attached where possible."
  else
    puts "Recipe model has no :photos attachment — skipping images."
  end

  # -------------------------
  # Summary
  # -------------------------
  puts "== DONE =="
  puts "Users:    #{User.count}"
  puts "Scans:    #{Scan.count}"
  puts "Recipes:  #{Recipe.count}"
  puts "Reviews:  #{Review.count}"
  if defined?(Favorite)
    puts "Favorites: #{Favorite.count}"
  end
  if defined?(ActsAsVotable::Vote)
    puts "Votes:     #{ActsAsVotable::Vote.count}"
  elsif ActiveRecord::Base.connection.table_exists?(:votes)
    puts "Votes:     #{Vote.count rescue 'n/a'}"
  end
end

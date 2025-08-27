puts "Destroying Database..."
User.destroy_all
Recipe.destroy_all
Scan.destroy_all

user1 = User.create!(
    username: "Douglass",
    allergy: "nuts",
    preference: nil,
    email: "douglass123@gmail.com",
    password: "123456"
  )
user2 = User.create!(
    username: "Kaleb",
    allergy: nil,
    preference: "vegetarian",
    email: "kaleb123@gmail.com",
    password: "123456"
  )
user3 = User.create!(
    username: "Pradillo",
    allergy: "seafood",
    preference: "vegan",
    email: "pradillo123@gmail.com",
    password: "123456"
  )
puts "Users created!"

puts "Making scans..."
user1scan = Scan.create!(user_id: user1.id)
user2scan = Scan.create!(user_id: user2.id)
user3scan = Scan.create!(user_id: user3.id)
puts "Scans created!"

puts "Making recipes..."
Recipe.create!(
  name: "Spaghetti Aglio e Olio",
  directions: "Cook pasta. Fry garlic in olive oil. Toss with parsley and chili flakes.",
  duration: 20,
  cuisine: "Italian",
  diet: "vegetarian",
  scan_id: user1scan.id
)

Recipe.create!(
  name: "Chicken Teriyaki Bowl",
  directions: "Cook chicken. Make teriyaki sauce. Serve with rice and steamed broccoli.",
  duration: 30,
  cuisine: "Japanese",
  diet: "high protein",
  scan_id: user1scan.id
)

Recipe.create!(
  name: "Vegan Lentil Curry",
  directions: "Simmer lentils with coconut milk, tomatoes, and curry spices.",
  duration: 40,
  cuisine: "Indian",
  diet: "vegan",
  scan_id: user1scan.id
)

Recipe.create!(
  name: "Greek Salad",
  directions: "Chop cucumbers, tomatoes, onions. Add feta and olives. Dress with olive oil and oregano.",
  duration: 15,
  cuisine: "Greek",
  diet: "vegetarian",
  scan_id: user2scan.id
)

Recipe.create!(
  name: "Beef Tacos",
  directions: "Cook ground beef with spices. Serve in tortillas with lettuce, cheese, and salsa.",
  duration: 25,
  cuisine: "Mexican",
  diet: "omnivore",
  scan_id: user2scan.id
)

Recipe.create!(
  name: "Miso Soup",
  directions: "Boil dashi. Add miso paste, tofu cubes, and seaweed. Garnish with green onions.",
  duration: 15,
  cuisine: "Japanese",
  diet: "vegan",
  scan_id: user2scan.id
)

Recipe.create!(
  name: "Quinoa Buddha Bowl",
  directions: "Cook quinoa. Top with roasted veggies, avocado, and tahini dressing.",
  duration: 35,
  cuisine: "Fusion",
  diet: "vegan",
  scan_id: user3scan.id
)

Recipe.create!(
  name: "Pad Thai",
  directions: "Stir-fry rice noodles with tofu, egg, bean sprouts, and tamarind sauce.",
  duration: 30,
  cuisine: "Thai",
  diet: "vegetarian",
  scan_id: user3scan.id
)

Recipe.create!(
  name: "Shakshuka",
  directions: "Simmer tomatoes, peppers, and spices. Poach eggs in sauce. Garnish with parsley.",
  duration: 25,
  cuisine: "Middle Eastern",
  diet: "vegetarian",
  scan_id: user3scan.id
)

Recipe.create!(
  name: "Tacos",
  directions: "Cook ground beef with spices. Serve in tortillas with lettuce, cheese, and salsa.",
  duration: 25,
  cuisine: "Mexican",
  diet: "omnivore",
  scan_id: user3scan.id
)

Recipe.create!(
  name: "Vegan Curry",
  directions: "Simmer lentils with coconut milk, tomatoes, and curry spices.",
  duration: 40,
  cuisine: "Indian",
  diet: "vegan",
  scan_id: user3scan.id
)

Recipe.create!(
  name: "Vegan Curry",
  directions: "Simmer lentils with coconut milk, tomatoes, and curry spices.",
  duration: 40,
  cuisine: "Indian",
  diet: "vegan",
  scan_id: user3scan.id
)

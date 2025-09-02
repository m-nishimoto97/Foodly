# db/migrate/20250902_add_extended_fields_to_recipes.rb
class AddFiltersAndCaloriesToRecipes < ActiveRecord::Migration[7.1]
  def change
    change_table :recipes, bulk: true do |t|
      t.string  :localized_name
      t.integer :base_servings, default: 2, null: false

      t.text    :ingredients_html
      t.text    :directions_html
      t.text    :summary_html

      t.integer :calories_per_serving
      t.string  :method
      t.string  :meal_type
      t.integer :difficulty, default: 1, null: false
      t.integer :price_per_serving_cents
      t.string  :mood

      t.date    :best_season_start
      t.date    :best_season_end
    end

    add_index :recipes, :cuisine
    add_index :recipes, :diet
    add_index :recipes, :method
    add_index :recipes, :meal_type
    add_index :recipes, :difficulty
    add_index :recipes, :price_per_serving_cents
    add_index :recipes, :calories_per_serving
  end
end

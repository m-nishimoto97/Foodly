class ChangeIngredientsToJsonbInRecipes < ActiveRecord::Migration[7.1]
  def change
    # Remove the old ingrediens column
    remove_column :recipes, :ingredients, :string

    # Creates new column
    add_column :recipes, :ingredients, :jsonb, default: {}, null: false

    # Created a GIN Index for faster searching in PostgreSQL
    add_index :recipes, :ingredients, using: :gin
  end
end

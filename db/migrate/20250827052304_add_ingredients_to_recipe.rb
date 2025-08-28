class AddIngredientsToRecipe < ActiveRecord::Migration[7.1]

  def change
    add_column :recipes, :ingredients, :string
  end
end

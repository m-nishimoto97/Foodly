class AddIngredientsToScans < ActiveRecord::Migration[7.1]
  def change
    # Only saves as an array with PostgreSQL
    add_column :scans, :ingredients, :string, array: true, default: [], null: false
  end
end

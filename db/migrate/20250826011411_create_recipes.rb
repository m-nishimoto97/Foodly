class CreateRecipes < ActiveRecord::Migration[7.1]
  def change
    create_table :recipes do |t|
      t.string :name
      t.text :directions
      t.integer :duration
      t.string :cuisine
      t.string :diet
      t.references :scans, null: false, foreign_key: true
      t.timestamps
    end
  end
end

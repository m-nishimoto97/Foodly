class AddColumnToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :allergy, :string
    add_column :users, :preference, :string
    add_column :users, :username, :string
  end
end

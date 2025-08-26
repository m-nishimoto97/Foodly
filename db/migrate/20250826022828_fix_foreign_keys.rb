class FixForeignKeys < ActiveRecord::Migration[7.1]
  def change
    rename_column :recipes, :scans_id, :scan_id
    rename_column :scans, :users_id, :user_id
  end
end

class AddConfidentielFieldToAvis < ActiveRecord::Migration[5.0]
  def change
    add_column :avis, :confidentiel, :boolean, default: false, null: false
  end
end

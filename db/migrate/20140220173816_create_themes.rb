class CreateThemes < ActiveRecord::Migration[4.2]
  def change
    create_table :themes do |t|
      t.string :name
      t.text :description

      t.timestamps null: false
    end
  end
end

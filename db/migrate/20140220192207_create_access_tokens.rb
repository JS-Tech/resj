class CreateAccessTokens < ActiveRecord::Migration
  def change
    create_table :access_tokens do |t|
      t.string :token
      t.boolean :valid
      t.belongs_to :ownership, index: true

      t.timestamps
    end
  end
end

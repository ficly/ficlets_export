class CreateAuthors < ActiveRecord::Migration[5.2]
  def change
    create_table :authors do |t|
      t.string :name
      t.string :favorite_book
      t.string :favorite_author
      t.text :bio
      t.string :uri_name
      t.timestamps
    end
  end
end

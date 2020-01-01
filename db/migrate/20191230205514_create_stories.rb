class CreateStories < ActiveRecord::Migration[5.2]
  def change
    create_table :stories do |t|
      t.integer :orig_id
      t.integer :archive_id
      t.string :author_short
      t.string :author_name
      t.string :title
      t.string :photo_url
      t.string :photo_link
      t.string :photo_title
      t.string :photo_author
      t.boolean :is_mature
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :published_at
    end
  end
end

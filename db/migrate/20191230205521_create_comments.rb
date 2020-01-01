class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.integer :orig_id
      t.text :body
      t.datetime :published_at
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :author_id
      t.integer :story_id
    end
  end
end

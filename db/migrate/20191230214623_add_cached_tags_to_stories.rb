class AddCachedTagsToStories < ActiveRecord::Migration[5.2]
  def change
    add_column :stories, :cached_tags, :text
  end
end

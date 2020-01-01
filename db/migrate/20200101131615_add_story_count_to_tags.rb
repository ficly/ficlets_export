class AddStoryCountToTags < ActiveRecord::Migration[5.2]
  def change
    add_column :tags, :story_count, :integer, default: 0
  end
end

class AddSequelsAndPrequelsToStories < ActiveRecord::Migration[5.2]
  def change
    change_table :stories do |t|
      t.text :sequels
      t.text :prequels
    end
  end
end

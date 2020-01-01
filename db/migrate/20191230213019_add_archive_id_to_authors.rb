class AddArchiveIdToAuthors < ActiveRecord::Migration[5.2]
  def change
    add_column :authors, :archive_id, :integer
  end
end

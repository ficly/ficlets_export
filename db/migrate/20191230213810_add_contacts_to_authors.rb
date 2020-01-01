class AddContactsToAuthors < ActiveRecord::Migration[5.2]
  def change
    add_column :authors, :contacts, :text
  end
end

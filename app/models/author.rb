class Author < ApplicationRecord
  serialize :contacts


  def self.import_from_json(o)
    author = Author.find_or_initialize_by(uri_name: o['uri_name'])
    o['archive_id'] = o['id']
    o.delete('id')
    author.update(o)
  end

  def stories
    @stories ||= Story.where(author_short: self.uri_name)
  end

end

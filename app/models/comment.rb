require 'will_paginate'
class Comment < ActiveRecord::Base
	belongs_to :author, optional: true
	belongs_to :story, optional: true

	# index :user_id
	#index [:resource_id, :resource_type]
  #
	# validates_length_of :body,
	# 	:in => 1..1024

  def self.import_from_json(o)
    comment = Comment.find_or_initialize_by(orig_id: o['orig_id'])
    comment.orig_id = o['id']
    o.delete('id')

    story = Story.where(archive_id: o['story_id']).first || Story.where(orig_id: o['story_id']).first
    author = Author.where(archive_id: o['author_id']).first || Author.where(orig_id: o['author_id']).first

    o['story_id'] = story.id unless story.nil?
    o['author_id'] = author.id unless story.nil?

    comment.update(o)
  end

  def user
    author
  end

  def to_html
    self.body.html_safe
  end

	# def to_html
	# 	r = RedCloth.new(self.body)
	# 	r.sanitize_html = true
	# 	return r.to_html
	# end

  def for_association
    out = {
      id: self.id,
      body: self.to_html,
      date: self.created_at,
      user: nil
    }

    if user.nil?
      out[:user] = {
        id: nil,
        name: "Deleted User",
        uri_name: ""
      }
    else
      out[:user] = self.user.for_association
    end

    out
  end

	protected

	# def before_validation
  #   sanitizer = HTML::FullSanitizer.new
  #   self.body = sanitizer.sanitize(self.body.strip)
  # end
  #
	# def after_create
	# 	unless resource.nil?
	# 		ReputationEvent.create(
	# 		:resource => resource,
	# 		:event_type => "comment",
	# 		:user => user
	# 		)
	# 	end
	# end
end

class Tag < ApplicationRecord
  serialize :story_ids

  def stories
    @stories ||= Story.where(orig_id: self.story_ids).order("orig_id asc")
  end

  def self.generate_tags
    Story.find_each do |story|
      story.tags.each do |tag|
        t = Tag.find_or_initialize_by(tag: tag)
        t.story_ids = [] if t.story_ids.blank?
        t.story_ids << story.orig_id unless t.story_ids.include?(story.orig_id)
        t.story_ids.sort!
        t.story_count = t.story_ids.length
        t.save
      end
    end
  end

end

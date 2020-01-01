class Tag < ApplicationRecord
  serialize :story_ids

  before_save :clean_tag

  def self.clean_tag(tag)
    return nil if tag.blank?
    tag.squish.strip.downcase.gsub(" ","-").gsub(/[^a-z0-9:-]/,"").gsub("--", "-")
  end

  def self.clean_tags(tags)
    if tags.is_a?(String)
      tags = tags.split(",")
    end
    tags.map do |tag|
      Tag.clean_tag(tag)
    end
  end

  def stories
    @stories ||= Story.where(orig_id: self.story_ids).order("orig_id asc")
  end

  def self.generate_tags
    Story.find_each do |story|
      story.tags.each do |tag|
        tag = Tag.clean_tag(tag)
        t = Tag.find_or_initialize_by(tag: tag)
        t.story_ids = [] if t.story_ids.blank?
        t.story_ids << story.orig_id unless t.story_ids.include?(story.orig_id)
        t.story_ids.sort!
        t.story_count = t.story_ids.length
        t.save
      end
    end
  end

  def clean_tag
    self.tag = Tag.clean_tag(self.tag)
  end

end

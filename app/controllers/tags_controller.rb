class TagsController < ApplicationController

  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @tags = Tag.where.not(tag: [nil, "", '-', 'page']).where("story_count > 0").order('story_count desc, tag asc').paginate(page: @page, per_page: 250)
  end

  def show
    @tag = Tag.find_by(tag: params[:id])
    #story_ids = @tag.taggings.where(taggable_type: "Story").pluck(:taggable_id)
    @stories = @tag.stories.paginate(page: 1, per_page: 50)
    # challenge_ids = @tag.taggings.where(taggable_type: "Challenge").pluck(:taggable_id)
    # @challenges = Challenge.where(id: challenge_ids).order("id asc").paginate(page: 1, per_page: 50)
  end

  def stories
    @tag = Tag.find_by(tag: params[:id])
    @page = params[:page].to_i
    @page = 1 if @page < 1
    #story_ids = @tag.taggings.where(taggable_type: "Story").pluck(:taggable_id)
    @stories = @tag.stories.paginate(page: @page, per_page: 50)
  end
  #
  # def challenges
  #   @tag = Tag.find_by(cleaned_tag: params[:id])
  #   @page = params[:page].to_i
  #   @page = 1 if @page < 1
  #   challenge_ids = @tag.taggings.where(taggable_type: "Challenge").pluck(:taggable_id)
  #   @challenges = Challenge.where(id: challenge_ids).order("id asc").paginate(page: @page, per_page: 50)
  # end


end

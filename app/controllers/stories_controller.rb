class StoriesController < ApplicationController

  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1

    @stories = Story.published.order("orig_id asc").paginate(page: @page, per_page: 100)
    @total_pages = @stories.total_pages
  end

  def show
    @story = Story.where(orig_id: params[:id]).first
    @user = @story.user
    @tags = @story.tags
    @sequels = Story.where(orig_id: @story.sequels) #@story.sequels.includes(:user)
    @prequels = Story.where(orig_id: @story.prequels) #@story.prequels.includes(:user)
  end

  def comments
    @story = Story.where(orig_id: params[:id]).first
    @comments = @story.comments.order("orig_id asc")
  end

end

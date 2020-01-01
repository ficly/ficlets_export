class AuthorsController < ApplicationController

  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @authors = Author.order("name asc").paginate(page: @page, per_page: 100)
  end

  def show
    @author = Author.where(uri_name: params[:id]).first
    if @author.nil?
      flash[:alert] = "No author found."
      redirect_to authors_path and return
    end
    @stories = @author.stories.order("published_at asc")
  end

end

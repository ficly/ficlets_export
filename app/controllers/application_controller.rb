require "fileutils"

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # You only want to do this if you really mean it,
  # and probably only after you've written the rake task:

  after_action :export_content

  protected

  def export_content
    output_dir = "tmp/export"
    file_dir = "#{output_dir}/#{request.path}"
    FileUtils.mkdir_p(file_dir)
    f = File.open("#{file_dir}/index.html", "w+")
    f.puts response.body.squish
    f.close
    true
  end
end

namespace :export do

  task :import => :environment do
    # Authors
    files = Dir.glob("db/export/authors/*.json")
    files.each do |f|
      o = JSON.parse(JSON.iconv('UTF-8', 'ISO-8859-1', File.read(f)))
      Author.import_from_json(o['author'])
    end
    # Stories
    files = Dir.glob("db/export/stories/*.json")
    files.each do |f|
      o = JSON.parse(JSON.iconv('UTF-8', 'ISO-8859-1', File.read(f)))
      Story.import_from_json(o['story'])
    end
    # Comments
    files = Dir.glob("db/export/comments/*.json")
    files.each do |f|
      o = JSON.parse(JSON.iconv('UTF-8', 'ISO-8859-1', File.read(f)))
      Comment.import_from_json(o['comment'])
    end
  end

  task :all do

    f = File.open("tmp/export/.htaccess", "w+")
    f.puts %(RewriteEngine On
RewriteCond %{SERVER_PORT} 80
RewriteRule ^(.*)$ https://ficly.com/$1 [R,L])
    f.close

    [:assets, :authors, :stories, :tags].each do |t|
      start_time = Time.now
      puts "Starting: #{t}"
      Rake::Task["export:#{t}"].invoke
      end_time = Time.now
      puts "Finished: #{t} in #{end_time - start_time} seconds"
    end
  end

  task :assets => :environment do
    export_static("assets","application.js")
    export_static("assets","application.css")
    # http://localhost:3000/assets/average-rating-pencil.gif
    # export_static("assets","average-rating-pencil.gif", true)
    # export_static("assets","ficly-logo-circle.png", true)
    # export_static("assets","ficly-logo-footer.png", true)
    # export_static("assets","ficly-logo-text.png", true)
    # FileUtils.cp_r("public/icons", "tmp/export/")
  end

  task :stories => :environment do
    api.get("/")
    api.get("/stories")
    total_pages = Story.paginate(page: @page, per_page: 100).total_pages

    i = 1

    while i <= total_pages
      api.get("/stories/page/#{i}")
      i += 1
    end

    Story.find_each do |s|
      api.get("/stories/#{s.orig_id}")
      api.get("/stories/#{s.orig_id}/comments")
    end
  end
  #
  # task :pages => :environment do
  #   Page.find_each do |page|
  #     api.get("/pages/#{page.basename}")
  #   end
  # end

  # task :blog => :environment do
  #   api.get("/blog")
  #
  #   total_pages = BlogPost.paginate(page: @page, per_page: 25).total_pages
  #
  #   i = 1
  #
  #   while i <= total_pages
  #     api.get("/blog/page/#{i}")
  #     i += 1
  #   end
  #
  #   BlogPost.find_each do |post|
  #     api.get("/blog/#{post.basename}")
  #   end
  # end

  task :authors => :environment do
    api.get("/authors")

    total_pages = Author.paginate(page: @page, per_page: 100).total_pages

    i = 1

    while i <= total_pages
      api.get("/authors/page/#{i}")
      i += 1
    end

    Author.find_each do |user|
      api.get("/authors/#{user.uri_name}")
    end
  end

  task :tags => :environment do
    api.get("/tags")

    total_pages = Tag.where("story_count > 0").paginate(page: @page, per_page: 250).total_pages

    i = 1

    while i <= total_pages
      api.get("/tags/page/#{i}")
      i += 1
    end

    Tag.where("story_count > 0").find_each do |tag|
      api.get("/tags/#{tag.tag}/stories")

      story_ids = tag.story_ids
      total_pages = Story.where(orig_id: story_ids).paginate(page: 1, per_page: 50).total_pages
      i = 1

      if total_pages > 1
        while i <= total_pages
          api.get("/tags/#{tag.tag}/stories/#{i}")
          i += 1
        end
      end
    end

  end
  #
  # task :challenges => :environment do
  #   api.get("/challenges")
  #
  #   total_pages = Challenge.includes(:user).paginate(page: @page, per_page: 50).total_pages
  #
  #   i = 1
  #
  #   while i <= total_pages
  #     api.get("/challenges/page/#{i}")
  #     i += 1
  #   end
  #
  #   Challenge.find_each do |c|
  #     api.get("/challenges/#{c.id}")
  #   end
  # end

  def api
    @api ||= GetFiclets.new
  end

  def export_static(path, filename, binary=false)
    FileUtils.mkdir_p("tmp/export/#{path}")
    r = api.get("/#{path}/#{filename}")

    a = "w+"
    a = "wb+" if binary

    f = File.open("tmp/export/#{path}/#{filename}", a)
    f.puts r.body
    f.close
  end

end

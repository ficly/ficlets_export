require "will_paginate"

#require 'aws/s3'
#require 'redcloth_extensions'

class Story < ActiveRecord::Base
  serialize :sequels
  serialize :prequels
  serialize :cached_tags

	has_many :comments

	scope :published, -> {
		where("published_at is not null").order("published_at asc")
  }

	# validates_length_of :body, :in => 60..1024
	# validates_length_of :title, :in => 1..64

	# index :user_id
	#index [:user_id,:is_draft,:is_deleted], :order => "published_at desc"
	#index [:is_draft, :is_deleted], :order => "published_at desc"
	# index :sequel_to
	# index :prequel_to
	# index :is_draft

  def self.import_from_json(o)
    story = Story.find_or_initialize_by(orig_id: o['orig_id'])
    o['archive_id'] = o['id']
    o['author_name'] = o['author']
    o.delete('id')
    o.delete('author')
    story.update(o)
  end

  def author
    @author ||= Author.where(uri_name: self.author_short).first
  end

  def display_published_at
    return "" if self.published_at.nil?
    self.published_at.strftime( "%B #{self.published_at.day.ordinalize}, %Y" )
  end

  def user
    author
  end

  def tags
    return [] if self.cached_tags.blank?
    return @tags unless @tags.nil?
    @tags ||= self.cached_tags.split(",")
    @tags.map! do |t|
      t.strip
    end
    @tags
  end

  # For getting the middleman JSON stuff (also a good test of associations):

  def for_association
    out = {
      id: self.id,
      title: self.title,
      user: nil
    }
    if user.nil?
      out[:user] = User.default_user
    else
      out[:user] = user.for_association
    end

    out
  end

  def middleman_json
    out = {
      id: id,
      slug: id,
      title: title,
      date: published_at,
      description: snippet,
      published_at: published_at,
      average_rating: average_rating,
      featured_at: featured_at,
      tags: tags,
      prequels: [],
      sequels: [],
      comments: [],
      author: {

      }
    }

		if user.nil?
			out[:author] = User.default_user
		else
			out[:author] = user.for_association
		end

    comments.includes(:user).order("id asc").each do |comment|
      out[:comments] << {
        id: comment.id,
        user: comment.user.for_association,
        body: PandocRuby.convert(comment.body, from: :textile, to: :markdown)
      }
    end

    sequels.each do |sequel|
			seq = {
				id: sequel.id,
        title: sequel.title
			}

			if sequel.user.nil?
				seq[:author] = User.default_user
			else
				seq[:author] = sequel.user.for_association
			end

      out[:sequels] << seq
    end

    prequels.each do |prequel|
			seq = {
				id: prequel.id,
				title: prequel.title
			}
      out[:prequels] << {
        id: prequel.id,
        title: prequel.title
      }

			if prequel.user.nil?
				seq[:author] = User.default_user
			else
				seq[:author] = prequel.user.for_association
			end

			out[:prequels] << seq
    end

    out
  end

	def middleman_export
		json = middleman_json
		body = cached_html

<<-eos
;;;
#{JSON.pretty_generate(json)}
;;;
#{body}
eos
	end

	def self.middleman_export
		story_dir = "#{Rails.root}/tmp/stories"

		FileUtils.mkdir_p(story_dir) unless Dir.exists?(story_dir)

		Story.published.find_each do |story|

			puts "Writing: #{story.id}"
			f = File.open("#{story_dir}/#{story.published_at.strftime('%Y-%m-%d')}-#{story.id}.html","w+")
			f.puts story.middleman_export
			f.close
		end
	end

  def hugo_export
    json = middleman_json
    body = PandocRuby.convert(self.body, from: :textile, to: :markdown)

<<-eos
#{JSON.pretty_generate(json)}

#{body}
eos
  end

  def self.hugo_export
    story_dir = "#{Rails.root}/tmp/hugo/story"
    FileUtils.mkdir_p(story_dir)

    Story.published.find_each do |story|

			puts "Writing: #{story.id}"
      FileUtils.mkdir_p("#{story_dir}/#{story.id}")
			f = File.open("#{story_dir}/#{story.id}/index.md","w+")
			f.puts story.hugo_export
			f.close
		end
  end


	def self.backup_stories
		backup_dir = "#{RAILS_ROOT}/tmp/backup"
		Story.find_in_batches do |records|
			records.each {|story|
				out = story.to_xml(:include => {:user => {:only => [:uri_name, :name]}})
				f = File.open("#{backup_dir}/#{story.id}.xml",'w+')
				f.puts out
				f.close
			}
		end
		`tar cvf #{RAILS_ROOT}/tmp/backup.tar #{backup_dir}`
		`gzip #{RAILS_ROOT}/tmp/backup.tar`
		s3config = YAML.load(IO.read(File.join(RAILS_ROOT, "config", "amazon_s3.yml")))[RAILS_ENV]
		AWS::S3::Base.establish_connection!(
			:access_key_id => s3config['access_key_id'],
			:secret_access_key => s3config['secret_access_key']
		)
		AWS::S3::S3Object.store(
			"stories.tar.gz",
			open("#{RAILS_ROOT}/tmp/backup.tar.gz"),
			s3config['bucket_name'],
			:access => :public_read
		)
		`rm -f #{RAILS_ROOT}/tmp/backup/*`
		`rm -f #{RAILS_ROOT}/tmp/backup.tar.gz`
		true
	end

	def self.backup_db
		story = Story.find(:first)
    puts "#{story.id}"
		connection = Story.connection
		filename = "#{connection.current_database}_#{Time.now.to_i}.sql"
		database = "#{connection.current_database}"
		config = YAML.load(IO.read(File.join(RAILS_ROOT, "config", "database.yml")))[RAILS_ENV]
		s3config = YAML.load(IO.read(File.join(RAILS_ROOT, "config", "amazon_s3.yml")))[RAILS_ENV]
		`mysqldump -u #{config['username']} -p#{config['password']} -q #{database} > #{RAILS_ROOT}/db/#{filename}`
		`gzip #{RAILS_ROOT}/db/#{filename}`
		# S3 stuff to go here.
		AWS::S3::Base.establish_connection!(
			:access_key_id => s3config['access_key_id'],
			:secret_access_key => s3config['secret_access_key']
		)
		AWS::S3::S3Object.store("/db_backups/#{filename}.gz",open("#{RAILS_ROOT}/db/#{filename}.gz"),s3config['bucket_name'])
	end

	def self.random
		Story.published.find(:first, :select => :id, :offset => (Story.published.count * rand).to_i)
	end

	def self.paged_find_tagged_with(tags, args = {})
		if tags.blank?
			paginate args
		else
			options = find_options_for_find_tagged_with(tags, :match_all => true)
			options.merge!(args)
			# The default count query generated by paginate includes COUNT(DISTINCT Posts.*) which errors, at least on mysql
			# Below we override the default select statement used to perform the count so that it becomes COUNT(DISTINCT Posts.id)
			paginate(options.merge(:count => { :select => options[:select].gsub('*', 'id') }))
		end
	end

	def self.featured
		self.one_featured.first
	end

	def self.calculate_featured_by_range(start_date,end_date)
		d = end_date
		while(d >= start_date)
			Story.calculate_featured(d)
			d = d.advance(:days => -1)
		end
	end

	def self.calculate_activity_rating(date=nil)
		if date.nil?
			pass_date = false
			date = Time.now
		else
			pass_date = true
		end
		page = 1
		while (page)
			stories = Story.published.paginate(:page => page, :conditions => ["published_at <= ?",date])
			stories.each do |story|
				if pass_date
					story.calculate_activity_rating(date)
				else
					story.calculate_activity_rating
					story.save
				end
			end
			page = stories.next_page
		end
	end

	def self.calculate_featured(date=nil)
		if date.nil?
			date = Time.now.advance(:days => -1).midnight
		else
			date = date.midnight
		end
		Story.calculate_activity_rating(date)
		Story.set_featured_for_date(date)
	end

	def self.set_featured_for_date(date)
		date = date.midnight
		history = ActivityHistory.find(:first,:conditions => ["stories.is_mature = ? and active_at between ? and ?",false,date,date.advance(:hours => 24)],:order => "activity_histories.activity_rating desc",:include => :story)
		if history && history.story.featured_at.nil?
			history.story.featured_at = date
			history.story.save
		end
	end

	def calculate_activity_rating(date=nil)
		if date.nil?
			date = Time.now
			use_history = false
		else
			date = date.midnight
			use_history = true
		end
		start_date = date.advance(:days => -2)
		events = self.reputation_events.find(:all, :conditions => ["reputation_events.created_at between ? and ?",start_date,date])
		ratings = self.ratings.find(:all, :conditions => ["ratings.created_at between ? and ?",start_date,date])
		rating = 0
		events.each do |event|
			if event.event_type == "sequel" || event.event_type == "prequel"
				rating = rating+25 unless event.user_id == self.user_id
			elsif event.event_type == "rating"
				rating = rating+3 unless event.user_id == self.user_id
			elsif event.event_type == "view"
				rating = rating+1
			end
		end
		ratings.each do |r|
			if r.score < 3
				rating = rating - (2*r.score)
			else
				rating = rating + (1.5*r.score)
			end
		end
		rating = rating+(self.comments.count(:group => :user_id, :conditions => ["created_at between ? and ?",start_date,date]).length*10)
		l = self.body.length
		if l < 100
			rating = rating-30
		elsif l < 250
			rating = rating-20
		elsif l == 1024
			rating = rating + 20
		end
		if use_history
			return rating if rating < 1
			history = self.activity_histories.find_by_active_at(date) || self.activity_histories.new(:active_at => date)
			history.activity_rating = rating
			history.save!
		else
			self.activity_rating = rating
			self.view_count = self.reputation_events.count(:conditions => {:event_type => "view"})
		end
		return rating
	end

	def clean_average_rating
    0
		#self.average_rating.round
	# pair = self.average_rating.to_s.split(".")
	# left = pair[0].to_i
	# right = pair[1].to_i
	# if right == 0
	#   return left
	# else
	#   return self.average_rating
	# end
	end

	def generate_snippets
		r = RedCloth.new(body.strip)
		r.filter_styles = true
		r.filter_classes = true
		r.filter_ids = true
		r.no_span_caps = true
		r.sanitize_html = true
		self.cached_html = r.to_html
		self.snippet = self.clean_text(self.cached_html).slice(0..251)
		if self.snippet.length == 252
			self.snippet << "..."
		end
	end

  def to_middleman

  end

  def middleman_frontmatter
    {
      :id => id,
      :title => title,
      :published_at => published_at,
      :ratings_count => ratings_count,
      :average_rating => average_rating,
      :is_mature => is_mature,
      :type => "story"
    }
  end

	def to_html
		# r = RedCloth.new(self.body)
		# return r.to_html
		self.body
	end

	def short_url
		"http://s.ficly.com/#{self.id}"
	end

	def user_rating(user)
		ratings.each do |r|
			if r.user_id == user.id
				return r.score
			end
		end
		return nil
	end

	def clean_text(str)
		#sanitizer = HTML::FullSanitizer.new
		str.strip!
		str.squeeze!(" ")
		str.gsub!(/\r\n/,"\n")
    str
		#return sanitizer.sanitize(str)
	end

	def is_deletable?
		self.is_draft? || (self.prequels.count == 0 && self.sequels.count == 0)
	end

	protected
		def before_validation
			logger.debug(self.inspect)
			self.title = self.clean_text(self.title)
			self.body = self.clean_text(self.body)
			# self.title = clean_text(self.title)
			# self.body = clean_text(self.body)
		end

		# def before_save
		# 	unless is_draft? || !published_at.nil?
		# 		self.published_at = Time.now
		# 	end
		# 	unless is_draft? && new_record?
		# 		if Time.now.to_i - self.updated_at.to_i > 3600
		# 			self.view_count = self.view_events.count
		# 		end
		# 	end
		# 	self.generate_snippets
		# end
    #
		# def after_save
		# 	unless is_draft? || !published_at_was.nil?
		# 		self.reputation_events.create(
		# 			:event_type => "story_published",
		# 			:user_id => self.user_id
		# 		)
		# 	end
		# end
    #
		# def after_create
		# 	unless self.user_id.nil?
		# 		self.reputation_events.create(
		# 			:event_type => "story_create",
		# 			:user_id => self.user_id
		# 		)
		# 	end
		# end
end

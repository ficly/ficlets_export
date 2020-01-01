# The Ficlets Export Project

This won't do you much good if you don't have the data, but this is my attempt to turn the old Ficlets Archive into a static export.  I ended up building a Rails app and then writing a bunch of rake tasks and and after_action filter to just dump out all the files as cleanly as possible.  It's a shameless clone of the [Ficly Export](https://github.com/ficly/ficly_export), with a few things changed to work with ficlets instead.

It took too long, but it works.

## Local Setup

### Requirements

* Ruby 2.6.5
* MySQL or MariaDB
  * The default database.yml is localhost, and root w/out a password.
  * The database name is `ficlets_export`

### Getting the Data

Everything is in db/export.  To import the authors, stories and comments, you can run:

* Create the local database: `rake db:create`
* You need to untar (`cd db/export && tar zxvf *.tar.gz`) all the backup files. Commiting over 100k small json files into git just felt rude.
* Import everything: `rake export:import` -- It will probably take a *while* to import everything.
* Import the tags...  
  * run `rails c`
  * then `Story.clean_tags`, which will clean all the tags in the stories.
  * then `Tag.generate_tags`, which will pull all the tags from the stories and create Tag records for them. Both of those will take a while.

### Setting up Rails

* You'll need to install Ruby 2.6.5 however you want to make that happen.
* Install the bundler gem: `gem install bundler`
* `bundle`

And there you go!

## TODO

* Could be better looking, especially on mobile. You're welcome to help with that and submit a pull request!
* Speed up the export process. You're also welcome to help with that.  To look at the monster as it is, check out lib/tasks/export.rake.

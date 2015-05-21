source 'http://rubygems.org'

gem 'rails', '4.1.10'
gem 'rails-observers'
gem 'activerecord-session_store'

# Bundle edge Rails instead:
#gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'json'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'autoprefixer-rails'
  gem 'sass-rails' #, github: 'rails/sass-rails'
  gem 'coffee-rails'
  gem 'coffee-script-source'

  # use dedicated version of sprockets, 3.0.0 is broken
  gem 'sprockets', '~> 2.0'

  gem 'uglifier'
  gem 'eco'
end

gem 'omniauth'
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-linkedin'
gem 'omniauth-google-oauth2'

gem 'twitter', '~> 5.13.0'
gem 'koala'
gem 'mail', '~> 2.5.0'

gem 'mime-types'

gem 'delayed_job_active_record'
gem 'daemons'

gem 'simple-rss'

# e. g. on linux we need a javascript execution
gem 'libv8'
gem 'execjs'
gem 'therubyracer'

# e. g. for mysql you need to load mysql
gem 'mysql2'
#gem 'sqlite3'

gem 'net-ldap'

gem 'writeexcel'
gem 'icalendar'

# event machine
gem 'eventmachine'
gem 'em-websocket'

# Gems used only for develop/test and not required
# in production environments by default.
group :development, :test do

  gem 'test-unit'
  gem 'spring'
  gem 'sqlite3'

  # code coverage
  gem 'simplecov'
  gem 'simplecov-rcov'

  # UI tests w/ Selenium
  gem 'selenium-webdriver'

  # livereload on template changes (html, js, css)
  gem 'guard', '>= 2.2.2', require: false
  gem 'guard-livereload',  require: false
  gem 'rack-livereload'
  gem 'rb-fsevent',        require: false

  # code QA
  gem 'rubocop'
end

gem 'puma'
gem 'kramdown'

gem 'prawn'
gem 'prawn-table'

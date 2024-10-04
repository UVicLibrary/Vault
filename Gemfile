source 'https://rubygems.org'

gem 'ruby-vips'
gem 'carrierwave-vips'

gem 'simple_xlsx_reader'

gem 'omniauth-cas'

gem 'redlock', '~> 1.3.2'

# Pin to 5.10.7 to avoid 'PermissionsControl is not a constructor' error
# DO NOT USE 5.10.9
gem 'tinymce-rails', '5.10.7'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~>5.2.4.6'
# Use sqlite3 as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'active-fedora', '~> 13.1' #, '>= 11.1.4'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
gem 'byebug'
group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  #gem 'byebug'

  gem 'i18n-debug', require: false
  gem 'i18n-tasks'
  gem 'rspec'
  gem 'rspec-rails', '>= 3.6.0'

  gem 'simplecov', require: false

  gem 'fcrepo_wrapper', '~> 0.4'
  gem 'solr_wrapper', '~> 2.0'

  gem 'rubocop', '~> 0.50', '<= 0.52.1'
  gem 'rubocop-rspec', '~> 1.22', '<= 1.22.2'

  gem 'shoulda-matchers', require: false
  gem 'shoulda-callback-matchers', require: false

  gem 'rails-perftest'
  gem 'ruby-prof'
end

group :test do
  gem 'capybara'
  gem 'chromedriver-helper'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  # rack-test >= 0.71 does not work with older Capybara versions (< 2.17). See #214 for more details
  gem 'rack-test', '0.7.0'
  gem 'rails-controller-testing'
  gem 'rspec-activemodel-mocks'
  gem 'selenium-webdriver', '~> 3.142.7'
  gem 'webmock'
  gem 'carrierwave-aws'
  gem 'rspec-sidekiq'
  gem 'rspec-its'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'

  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 1.7'
  gem 'spring-watcher-listen', '~> 2.0.0'

  gem 'scss_lint', require: false
end

gem 'blacklight', '~> 6.7'
gem 'blacklight_oai_provider', '~> 6.0'
gem 'blacklight_range_limit', '~> 6.5'
gem 'blacklight_advanced_search'

# For exporting bagit bags from Vault
gem 'down'
gem 'posix-spawn'
gem 'http_parser.rb'
gem 'bagit'

gem 'hyrax', '3.6'
gem 'dry-monads', '< 1.5'

# Loading the env fails if psych > 3.0
gem 'psych', '3.3.4'
# ActiveFedora::Cleaner.clean! fails with addressable > 2.8.1
gem 'addressable', '2.8.1'

gem 'hyrax-doi', git: 'https://github.com/samvera-labs/hyrax-doi.git', branch: 'hyrax_upgrade'
gem 'rsolr', '~> 2.0'

gem 'devise'
gem 'devise-guests', '~> 0.3'
gem 'devise-i18n'
gem 'devise_invitable', '~> 1.6' #, '~> 2.0.6'

gem 'apartment'
gem 'config', '~> 2.2', '>= 2.2.1'
gem 'is_it_working'
gem 'rolify'

gem 'flipflop', '~> 2.3'
gem 'lograge'

gem 'zk'

gem 'mods', '~> 2.1'
gem 'riiif', '~> 1.1'

gem 'iiif_manifest', '~> 0.5.0'
gem 'draper'

gem 'sidekiq', '~> 6.4.0'
gem 'redis', '4.6'
gem 'sidekiq-cron'

gem 'cdm_migrator', '3.4.2'
gem 'to_spotlight', '~> 0.2.7'

gem 'secure_headers'

gem 'honeybadger', '~> 3.0'

gem 'pdfjs_viewer-rails'

# https://github.com/mislav/will_paginate
# gem 'will_paginate', '3.1.5'
# https://github.com/yrgoldteeth/bootstrap-will_paginate
gem 'bootstrap-will_paginate', '1.0.0'

gem 'edtf-humanize'
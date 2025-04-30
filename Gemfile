source 'https://rubygems.org'

# This is the Rails version normally allowed by Hyrax 4
# gem 'rails', '~> 6.0.5'

# This is the Rails version that Hyku 6 (Hyrax 5) uses
gem 'rails', '~> 6.0', github: 'rails/rails', branch: '6-1-stable', ref: 'd16199e507086e3d54d94253b7e1d87ead394d9f'

gem 'hyrax', '~> 4.0'
gem 'sass-rails', '~> 6.0'
gem 'bootstrap', '~> 4.0'

gem 'riiif', git: 'https://github.com/UVicLibrary/riiif'

gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'

# TO DO: Relax reqs for cdm_migrator
gem 'cdm_migrator', git: 'https://github.com/UVicLibrary/cdm_migrator'

# Prevents an error like ffi-1.17.0 requires rubygems version >= 3.3.22
# gem "ffi", "< 1.17.0"

# Use a branch that includes the ability to configure different
# processors for image derivatives. This lets us override the gem
# to use libvips for image derivatives instead of imagemagick/graphicsmagick.
# (Note: hydra-derivatives v.4 will also include this feature.)
# The current branch is pinned to Hyrax 4.x, hydra-derivatives < 4, Rails 6.
# Original commit/context: https://github.com/samvera/hydra-derivatives/pull/255
gem 'hydra-derivatives', git: 'https://github.com/samvera/hydra-derivatives.git', ref: 'f38ea44deb23033e7aac5d8dbce9c2a2502f05f3'

gem 'ruby-vips'
gem 'carrierwave-vips'

gem 'simple_xlsx_reader'

gem 'omniauth-cas'

gem 'redlock', '~> 1.3.2'

# Pin to 5.10.7 to avoid 'PermissionsControl is not a constructor' error
# DO NOT USE 5.10.9
gem 'tinymce-rails', '5.10.7'

# Use sqlite3 as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 3.7'

# Use Terser as compressor for JavaScript assets
# gem 'uglifier', '>= 1.3.0'
gem 'terser'

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

  # gem 'rubocop', '~> 0.50', '<= 0.52.1'
  # gem 'rubocop-rspec', '~> 1.22', '<= 1.22.2'
  gem 'rubocop', require: false

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

gem 'blacklight_oai_provider'
gem 'blacklight_range_limit'
gem 'blacklight_advanced_search'

# For exporting bagit bags from Vault
gem 'down'
gem 'posix-spawn'
gem 'http_parser.rb'
gem 'bagit'

# Loading the env fails if psych > 3.0
gem 'psych', '3.3.4'
gem 'stringio' # v.3.1.2 to fix Passenger/Psych error

# ActiveFedora::Cleaner.clean! fails with addressable > 2.8.1
gem 'addressable', '2.8.1'

gem 'hyrax-doi', github: 'samvera-labs/hyrax-doi', branch: 'rails_hyrax_upgrade'

gem 'rsolr', '~> 2.0'

gem 'devise'
gem 'devise-guests', '~> 0.3'
gem 'devise-i18n'
gem 'devise_invitable'

gem 'apartment', github: 'scientist-softserv/apartment', branch: 'development'
gem 'config', '~> 2.2', '>= 2.2.1'
gem 'is_it_working'
gem 'rolify'

gem 'flipflop', '~> 2.3'
gem 'lograge'

gem 'zk'

gem 'mods', '~> 2.1'
gem 'draper'

gem 'sidekiq', '~> 6.4.0'
gem 'redis', '4.6'
gem 'sidekiq-cron'

gem 'secure_headers'

gem 'honeybadger'

gem 'pdfjs_viewer-rails'

# https://github.com/mislav/will_paginate
# gem 'will_paginate', '3.1.5'
# https://github.com/yrgoldteeth/bootstrap-will_paginate
gem 'bootstrap-will_paginate', '1.0.0'

gem 'edtf-humanize'

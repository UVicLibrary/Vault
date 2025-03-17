Rails.application.configure do

  require 'socket'
  require 'ipaddr'
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = !!Sidekiq.server?

  config.active_job.queue_adapter = :async # :sidekiq

  # http://meta-lambda.com/rails-5-web-console-and-docker
  config.web_console.whitelisted_ips = Socket.ip_address_list.reduce([]) do |res, addrinfo|
    addrinfo.ipv4? ? res << IPAddr.new(addrinfo.ip_address).mask(24) : res
  end

  # Do not eager load code on boot.
  config.eager_load = false

  #config.assets.js_compressor = :terser

  config.cache_store = :file_store, "#{root}/tmp/cache"

  # Show full error reports.
  config.consider_all_requests_local = true

  config.assets.css_compressor = false

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  # config.assets.debug = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  config.serve_static_assets = true

  config.force_ssl = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  #

  config.action_mailer.default_options = { from: 'no-reply@uvic.ca' }
  config.action_mailer.default_url_options = { host: "localhost:3000" }

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end

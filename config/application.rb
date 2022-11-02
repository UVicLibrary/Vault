require_relative 'boot'

require 'rails/all'
require 'i18n/debug' if ENV['I18N_DEBUG']
#require 'ext/string'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Hyku
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # config.web_console.whitelisted_ips = '142.104.150.115'
    # config.web_console.permissions = '142.104.150.115'

    # Gzip all responses.  We probably could do this in an upstream proxy, but
    # configuring Nginx on Elastic Beanstalk is a pain.
    config.middleware.use Rack::Deflater

    # The locale is set by a query parameter, so if it's not found render 404
    config.action_dispatch.rescue_responses.merge!(
      "I18n::InvalidLocale" => :not_found
    )
config.middleware.use WebConsole::Middleware
    if defined? ActiveElasticJob
      # Rails.application.configure do
      #   config.active_elastic_job.process_jobs = Settings.worker == 'true'
      #   config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new }
      #   config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
      # end
    end

    config.to_prepare do
    	#Hyrax::ApplicationController.helper CdmMigrator::Application.helpers
      # Do dependency injection after the classes have been loaded.
      # Before moving this here (from an initializer) Devise was raising invalid
      # authenticity token errors.
      Hyrax::Admin::AppearancesController.form_class = AppearanceForm
    end

    config.before_initialize do
      if defined? ActiveElasticJob
        # Rails.application.configure do
        #   config.active_elastic_job.process_jobs = Settings.worker == 'true'
        #   config.active_elastic_job.aws_credentials = lambda { Aws::InstanceProfileCredentials.new }
        #   config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
        # end
      end
    end
  end
end

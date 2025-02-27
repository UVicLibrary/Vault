require_relative 'boot'

require 'rails/all'
require 'i18n/debug' if ENV['I18N_DEBUG']

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

ENV["IRB_USE_AUTOCOMPLETE"] = "false"

module Hyku
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # config.web_console.whitelisted_ips = '142.104.150.115'
    # config.web_console.permissions = '142.104.150.115'
    #
    config.time_zone = 'Pacific Time (US & Canada)'

    # config.paths.add "#{root}/lib/fast_update", eager_load: true
    config.paths.add "#{root}/app/services/doi", eager_load: true
    config.paths.add "#{root}/app/services/identifier", eager_load: true
    config.paths.add "#{root}/app/services/custom_searches", eager_load: true
    config.paths.add "#{root}/app/indexers/custom_indexing", eager_load: true

    config.paths.add "lib/queue_adapters", eager_load: true

    config.to_prepare do
      Dir.glob(Rails.root + "app/decorators/**/*_decorator*.rb").each do |c|
        require_dependency(c)
      end
    end

    # Gzip all responses.  We probably could do this in an upstream proxy, but
    # configuring Nginx on Elastic Beanstalk is a pain.
    config.middleware.use Rack::Deflater

    # The locale is set by a query parameter, so if it's not found render 404
    config.action_dispatch.rescue_responses.merge!(
      "I18n::InvalidLocale" => :not_found
    )
    
    if Rails.env.development?
      config.middleware.use WebConsole::Middleware
    end

    config.to_prepare do
    	#Hyrax::ApplicationController.helper CdmMigrator::Application.helpers
      # Do dependency injection after the classes have been loaded.
      # Before moving this here (from an initializer) Devise was raising invalid
      # authenticity token errors.
      Hyrax::Admin::AppearancesController.form_class = AppearanceForm
    end

    if defined?(ActiveElasticJob) && ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE', '') == 'elastic'
      Rails.application.configure do
        process_jobs = ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_ELASTIC_JOBS', false))
        config.active_elastic_job.process_jobs = process_jobs
        config.active_elastic_job.aws_credentials = -> { Aws::InstanceProfileCredentials.new }
        config.active_elastic_job.secret_key_base = Rails.application.secrets[:secret_key_base]
      end
    end

    ##
    # @api public
    #
    # @param relative_path [String] lookup the relative paths first in the Knapsack then in Hyku.
    #
    # @return [String] the path to the file, favoring those found in the knapsack but falling back
    #         to those in the Rails.root.
    # @see .theme_view_path_roots
    def self.path_for(relative_path)
      if defined?(HykuKnapsack)
        engine_path = HykuKnapsack::Engine.root.join(relative_path)
        return engine_path.to_s if engine_path.exist?
      end
      Rails.root.join(relative_path).to_s
    end

    ##
    # Psych Allow YAML Classes
    #
    # The following configuration addresses errors of the following form:
    #
    # ```
    # Psych::DisallowedClass: Tried to load unspecified class: ActiveSupport::HashWithIndifferentAccess
    # ```
    #
    # Psych::DisallowedClass: Tried to load unspecified class: <Your Class Name Here>
    config.after_initialize do
      yaml_column_permitted_classes = [
          Symbol,
          Hash,
          Array,
          ActiveSupport::HashWithIndifferentAccess,
          ActiveModel::Attribute.const_get(:FromDatabase),
          User,
          Time
      ]
      config.active_record.yaml_column_permitted_classes = yaml_column_permitted_classes
      # Seems at some point `ActiveRecord::Base.yaml_column_permitted_classes` loses all the values we set above
      # so we need to set it again here.
      ActiveRecord::Base.yaml_column_permitted_classes = yaml_column_permitted_classes
    end
  end
end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, prepend: true

  before_action :set_locale

  helper Openseadragon::OpenseadragonHelper
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Hydra::Controller::ControllerBehavior

  # Adds Hyrax behaviors into the application controller
  include Hyrax::Controller

  include Hyrax::ThemedLayoutController
  with_themed_layout '1_column'

  helper_method :current_account, :admin_host?

  before_action :require_active_account!, if: :multitenant?
  before_action :set_account_specific_connections!
  before_action :elevate_single_tenant!, if: :singletenant?

  before_action :add_honeybadger_context

  rescue_from Apartment::TenantNotFound do
    raise ActionController::RoutingError, 'Not Found'
  end

  ALLOWED_LOCALES = %w( de en es fr it zh ).freeze
  DEFAULT_LOCALE = 'en'.freeze

  protected

    def super_and_current_users
      users = Role.find_by(name: 'superadmin')&.users.to_a
      users << current_user if current_user && !users.include?(current_user)
      users
    end

  def set_locale
    I18n.locale = extract_locale_from_headers
  end

  private

    def extract_locale_from_headers
      browser_locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first if request.env['HTTP_ACCEPT_LANGUAGE']
      if ALLOWED_LOCALES.include?(browser_locale)
        browser_locale
      else
        DEFAULT_LOCALE
      end
    end

  def require_active_account!
    return if singletenant?
    return if devise_controller?
    raise Apartment::TenantNotFound, "No tenant for #{request.host}" unless current_account.persisted?
  end

  def set_account_specific_connections!
    current_account&.switch!
  end

  def multitenant?
    @multitenant ||= ActiveModel::Type::Boolean.new.cast(ENV.fetch('HYKU_MULTITENANT', false))
  end

  def singletenant?
    !multitenant?
  end

  def elevate_single_tenant!
    AccountElevator.switch!(current_account.cname) if current_account && root_host?
  end

  def root_host?
    Account.canonical_cname(request.host) == Account.root_host
  end

  def admin_host?
    return false if singletenant?
    Account.canonical_cname(request.host) == Account.admin_host
  end

  def current_account
    @current_account ||= Account.from_request(request)
    @current_account ||= if multitenant?
                           Account.new do |a|
                             a.build_solr_endpoint
                             a.build_fcrepo_endpoint
                             a.build_redis_endpoint
                           end
                         else
                           Account.single_tenant_default
                         end
  end

  # Add context information to the lograge entries
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.uuid
    payload[:user_id] = current_user.id if current_user
    payload[:account_id] = current_account.cname if current_account
  end

  def add_honeybadger_context
    Honeybadger.context(user_email: current_user.email) if current_user
  end

  def default_url_options(options={})
    options.merge(protocol: :https) if ActiveRecord::Type::Boolean.new.cast(ENV.fetch('HYKU_SSL_CONFIGURED', false))
  end


end
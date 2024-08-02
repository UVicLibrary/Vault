class User < ApplicationRecord

  # Since Hyku >= v.3, we force the use of the public users table so
  # that the same user account can be used across all tenants (rather
  # than creating an account per tenant). Otherwise, switching tenants
  # will also switch the users table to <tenant id>.users
  self.table_name = "public.users"

  # Includes lib/rolify from the rolify gem
  rolify
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Hyrax behaviors.
  include Hyrax::User
  include Hyrax::UserUsageStats

  attr_accessible :email, :password, :password_confirmation if Blacklight::Utils.needs_attr_accessible?
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :invitable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, omniauth_providers: [:cas], authentication_keys: [:email]

  before_create :add_default_roles

  scope :for_repository, -> {
    joins(:roles)
  }

  mount_uploader :avatar, VipsAvatarUploader, mount_on: :avatar_file_name
  validates_with Hyrax::AvatarValidator

  # When a user authenticates via CAS (UVic login), find
  # an existing user by email or create a new user and
  # populate the model's attributes with info from
  # the CAS service
  def self.find_or_create_from_auth_hash(auth_hash)
    User.where(email: auth_hash.extra.eduPersonPrincipalName).first_or_create do |user|
      # This block only runs if a new user is being created,
      # NOT for an existing record
      if auth_hash.extra.cn
        # Staff profile, use first and last name
        user.display_name = auth_hash.extra.cn
      else
        # No name specified, use their Netlink ID
        user.display_name = auth_hash.extra.user
      end
      user.email = auth_hash.extra.eduPersonPrincipalName
      user.password = Devise.friendly_token[0,20]
      user.site_roles = ["uvic"]
      user.save!
      user
    end
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier.
  def to_s
    email
  end

  def is_superadmin
    has_role? :superadmin
  end

  # This comes from a checkbox in the proprietor interface
  # Rails checkboxes are often nil or "0" so we handle that
  # case directly
  def is_superadmin=(value)
    value = ActiveModel::Type::Boolean.new.cast(value)
    if value
      add_role :superadmin
    else
      remove_role :superadmin
    end
  end

  def site_roles
    roles.site
  end

  def site_roles=(roles)
    roles.reject!(&:blank?)

    existing_roles = site_roles.pluck(:name)
    new_roles = roles - existing_roles
    removed_roles = existing_roles - roles

    new_roles.each do |r|
      add_role r, Site.instance
    end

    removed_roles.each do |r|
      remove_role r, Site.instance
    end
  end

  def groups
    #return ['admin'] if has_role?(:admin, Site.instance)
    site_roles.map {|r| r.name }
  end

  ##
  # @return [String] a name for the user
  def name
    return display_name if display_name.present?
    # regex for email addresses
    if user_key.match(/([a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9_-]+)/)
      user_key.split("@").first
    else
      user_key
    end
  end

  private

  def add_default_roles
    # byebug
    # Do not add the default admin role in test mode
    add_role :admin, Site.instance unless
      # self.class.any? || Account.global_tenant?
      self.class.joins(:roles).where("roles.name = ?", "admin").any? || Account.global_tenant?
  end
end
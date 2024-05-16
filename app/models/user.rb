class User < ApplicationRecord
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

  # before_create :add_default_roles

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
      add_role :admin, Site.instance unless self.class.any? || Account.global_tenant?
    end
end

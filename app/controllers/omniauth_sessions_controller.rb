# frozen_string_literal: true
class OmniauthSessionsController < Devise::SessionsController

  def create
    # Rails.logger.warn "sessions controller auth hash = #{auth_hash.inspect}"
    @user = User.find_or_create_from_auth_hash(auth_hash)
    update_existing_user(@user, auth_hash)
    @current_user = @user
    flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: "UVic")
    sign_in_and_redirect(@user)
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end

  def update_existing_user(user, auth_hash)
    update_permissions(user)
    update_display_name(user, auth_hash.extra.cn)
  end

  # Update the display name for existing database users if
  # they haven't provided one
  def update_display_name(user, display_name)
    unless user.display_name?
      user.display_name = display_name
      user.save!
    end
  end

  # Give the user a "uvic" site role. Blacklight Access
  # Controls needs this to allow access to works with
  # "institution" visibility.
  def update_permissions(user)
    # If a user is an admin, cataloguer, or already has
    # a uvic role, this isn't necessary
    unless ["admin","cataloguer","uvic"].any? { |role| user.site_roles.map(&:name).include?(role) }
      user.site_roles = user.site_roles + ["uvic"]
      user.save!
    end
  end

end
Rails.application.config.to_prepare do
  Blacklight::AccessControls::Ability.module_eval do
    # Overrides lib/blacklight/access_controls/ability.rb

    # The default behaviour adds a 'registered' group any
    # time a new user is created. But in Vault, the 'registered'
    # group doesn't come with any meaningful difference in
    # permissions since it's not our registered group name.
    # Also, we don't want invited users to be automatically
    # included in the 'uvic' group anyway.
    def user_groups
      return @user_groups if @user_groups

      @user_groups = default_user_groups
      @user_groups |= current_user.groups if current_user.respond_to? :groups
      # @user_groups |= ['registered'] unless current_user.new_record?
      @user_groups
    end

  end
end
class Ability
  include Hydra::Ability
  include Hyrax::Ability

  self.ability_logic += %i[
    everyone_can_create_curation_concerns
    group_permissions
    superadmin_permissions
    custom_permissions
    cataloguer_permissions
  ]

  # Define any customized permissions here.
  def custom_permissions
    return unless admin? || cataloguer?
    #can [:create], Account
    
    if can? [:manage, :create], Collection
      can [:create, :destroy, :update], FeaturedCollection
    end

  end

  def admin_permissions
    return unless admin?
    return if superadmin?

    super
    can [:manage], [Site, Role, User]

    can [:read, :update], Account do |account|
      account == Site.account
    end
  end

  def group_permissions
    return unless admin?

    can :manage, Hyku::Group
  end

  def cataloguer_permissions
  	  return unless cataloguer?
  	  alias_action :edit, to: :update
      alias_action :show, to: :read
      alias_action :discover, to: :read
      can :manage, ::AdminSet
  	  can :manage, ::Collection
  	  can :manage, ::FileSet
  	  can [:manage, :edit], ::SolrDocument
  	  can [:read, :create, :edit, :manage], curation_concerns_models 
  	  can :manage, Sipity::WorkflowResponsibility
  end
  
  def superadmin_permissions
    return unless superadmin?

    can :manage, :all
    can [:read, :update], Account do |account|
      account == Site.account
    end
    can :peek, Hyku::Application
  end

  def superadmin?
    current_user.has_role? :superadmin
  end
  
  def cataloguer?
  	  role = Role.where(name: "cataloguer", resource_type: "Site").first
  	  @cataloguer ||= current_user.site_roles.include? role rescue false
  end
end

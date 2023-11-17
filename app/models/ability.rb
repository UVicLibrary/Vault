class Ability
  include Hydra::Ability
  include Hyrax::Ability

  # Defined in hydra-head gem
  # hydra-head/hydra-access-controls/app/models/concerns/hydra/ip_based_ability.rb
  # Adds "uvic" group to users whose IPs are on campus
  include Hydra::IpBasedAbility

  self.ability_logic += %i[
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
  end

  def superadmin?
    current_user.has_role? :superadmin
  end
  
  def cataloguer?
  	  role = Role.where(name: "cataloguer", resource_type: "Site").first
  	  @cataloguer ||= current_user.site_roles.include? role rescue false
  end

  #####################################
  # Here lies modified methods from Hyrax::Ability
  #####################################

  def extract_subjects(subject)
    case subject
    when Hyrax::WorkShowPresenter, Hyrax::FileSetPresenter, Hyrax::CollectionPresenter,
        VaultWorkShowPresenter, VaultFileSetPresenter, VaultCollectionPresenter
      extract_subjects(subject.solr_document)
    when Draper::Decorator
      extract_subjects(subject.model)
    else
      super
    end
  end

  # Returns true if can create at least one type of work and they can deposit
  # into at least one AdminSet
  def can_create_any_work?
    Hyrax.config.curation_concerns.any? do |curation_concern_type|
      can?(:create, curation_concern_type)
    end #&& admin_set_with_deposit?
  end

  def editor_abilities
    can :read, ContentBlock
    return unless admin?

    can :read, :admin_dashboard
    can :update, ContentBlock
    can :edit, ::SolrDocument
    can :edit, Hyrax::SolrDocument::OrderedMembers
  end

  # Restore Blacklight Access Controls default. Default Hyrax makes this
  # an alias for :read, but we need to separate them to enable/disable
  # downloads at the collection level

  def download_groups(id)
    doc = permissions_doc(id)
    if Account.find_by(tenant: Apartment::Tenant.current).name == "iaff"
      dg =  Array(doc[self.class.download_group_field]) +
          Array(doc[self.class.edit_group_field])
      dg << "public" if doc['visibility_ssi'] == "open"
      dg
    else # Vault
      return [] if doc.nil?
      # Also grant all groups with edit access permission to download
      dg =  Array(doc[self.class.download_group_field]) +
            Array(doc[self.class.edit_group_field])
      Rails.logger.debug("[CANCAN] download_groups: #{dg.inspect}")
      dg
    end
  end

  def download_users(id)
    doc = permissions_doc(id)
    return [] if doc.nil?
    # Also grant all users with edit access permission to download
    users = Array(doc[self.class.download_user_field]) +
            Array(doc[self.class.edit_user_field])
    Rails.logger.debug("[CANCAN] download_users: #{users.inspect}")
    users
  end

  # Return the whole document for now since the Solr query doesn't
  # actually capture download groups or download users
  def permissions_doc(id)
    SolrDocument.find(id)
  end
end

require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/file_sets_controller.rb')

# OVERRIDE class from Hyrax v. 3.5
Hyrax::FileSetsController.class_eval do

  # Defined in the hydra-head gem
  # hydra-head/hydra-core/app/controllers/concerns/hydra/controller/ip_based_ability.rb
  include Hydra::Controller::IpBasedAbility


  def show_presenter
    # Tenant-specific file set presenters
    if Settings.multitenancy.enabled
      if current_account.cname.include? "vault"
        VaultFileSetPresenter
      elsif current_account.cname.include? "iaff"
        Hyrax::FileSetPresenter
      end
    else
      VaultFileSetPresenter
    end
  end

  def edit
    initialize_edit_form
    @parent = presenter.parent
  end

end
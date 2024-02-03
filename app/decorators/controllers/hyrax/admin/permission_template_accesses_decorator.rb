require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/admin/permission_template_accesses_controller.rb')

# OVERRIDE class from Hyrax v. 3.2.0
Hyrax::Admin::PermissionTemplateAccessesController.class_eval do

  # If it succeeds, the destroy action redirects to a custom
  # dashboard/collections controller action that asks the user
  # if they'd like to apply the collection's permissions
  # to all its member works.

  def after_destroy_success
    if source.admin_set?
      redirect_to hyrax.edit_admin_admin_set_path(source_id,
                                                  anchor: 'participants'),
                  notice: translate('participants', scope: 'hyrax.admin.admin_sets.form.permission_update_notices')
    else
      redirect_to(main_app.confirm_collection_access_permission_path(source_id, referer: update_referer),
                  notice: translate('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices'))
    end
  end

  # The tab that user was previously on before updating permissions
  def update_referer
    edit_dashboard_collection_path(source_id) +
        (params[:referer_anchor] || '')
  end

end
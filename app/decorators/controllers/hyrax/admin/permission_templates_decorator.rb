require_dependency Hyrax::Engine.root.join('app/controllers/hyrax/admin/permission_templates_controller.rb')

# OVERRIDE class from Hyrax v. 3.2.0
Hyrax::Admin::PermissionTemplatesController.class_eval do

  # If it succeeds, the update action redirects to a custom
  # dashboard/collections controller action that asks the user
  # if they'd like to apply the collection's permissions
  # to all its member works.

  # Note: Only adding a user to the list of viewers triggers this
  # action. Adding a group redirects to dashboard/collections_controller#update,
  # and removing a user or group redirects to admin/permission_template_accesses#destroy.
  # Weird.

  def update
    update_info = form.update(update_params)
    if update_info[:updated] == true # Ensure we redirect to currently active tab with the appropriate notice
      redirect_to(main_app.confirm_collection_access_permission_path(params[:collection_id], referer: update_referer),
                  notice: translate('sharing', scope: 'hyrax.dashboard.collections.form.permission_update_notices'))
    else
      redirect_to_edit_path_with_error(update_info)
    end
  end

  def update_referer
    request.referer + params[:referer_anchor]
  end

end


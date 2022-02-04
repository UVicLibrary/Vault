class VisibilityPermissionsMailer < HykuMailer
# Mailer for notifying user that a job has finished
  def inherit_visibility
    @user_email = params[:user_email]
    @collection = Collection.find(params[:id])
    host = params[:account_host]
    @visibility = params[:visibility]
    if @visibility == "open"
      @url = "#{host}/collections/#{@collection.id}"
    else
      @url = "#{host}/dashboard/collections/#{@collection.id}"
    end
    # Send email
    mail(to: @user_email, subject: 'Job Completed')
  end

  def inherit_permissions
    @user_email = params[:user_email]
    @collection = Collection.find(params[:id])
    host = params[:account_host]
    @url = "#{host}/collections/#{@collection.id}"
    mail(to: @user_email, subject: 'Job Completed')
  end

end

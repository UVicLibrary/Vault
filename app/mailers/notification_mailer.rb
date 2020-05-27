# app/mailers/hyrax/notification_mailer
  # Mailer for notifying user that a job has finished
  class NotificationMailer < HykuMailer

    def email_notification
      @user_email = params[:user_email]
      @collection = Collection.find(params[:id])
      host = params[:account_host]
      if params[:visibility]
        @visibility = params[:visibility]
        if @visibility == "public"
          @url = "https://#{host}/collections/#{@collection.id}"
        else # == "private"
          @url = "https://#{host}/dashboard/collections/#{@collection.id}"
        end
      end
      # Send email
      mail(to: @user_email, subject: 'Job Completed')
    end

  end

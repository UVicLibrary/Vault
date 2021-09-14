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
    
    def failures # For reindexing dates
    	@user_email = params[:user_email]
    	@failures = params[:failures]
    	mail(to: @user_email, subject: 'Job Completed with Failures') if @failures
    end

    def fixity_failures
      @file_sets = params[:file_sets]
      # Get a user email from config
      email_addresses = Settings.fixity_email
      email_addresses.each do |a|
        mail(to: a, subject: "Fixity Check - Possible Corrupted Files")
      end
    end

    def batch_create_files_failures
      @user_email = params[:user_email]
      @error_message = params[:error_message]
      @work_id = params[:work_id]
      mail(to: @user_email, subject: 'File Creation Error')
    end

  end

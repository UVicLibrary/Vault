# Mailer for notifying user that a job has finished
class DownloadsMailer < HykuMailer

  def send_email
    @user_email = params[:user_email]
    @collection = Collection.find(params[:id])
    host = "https://vault.library.uvic.ca"
    if params[:downloadable]
      @downloadable = ActiveModel::Type::Boolean.new.cast(params[:downloadable])# "true" => true
      @url = "#{host}/dashboard/collections/#{@collection.id}"
    end
    # Send email
    mail(to: @user_email, subject: 'Job Completed')
  end

end
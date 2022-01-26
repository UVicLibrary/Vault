# Mailer for notifying user that a job has finished
class DownloadsMailer < HykuMailer

  def send_email
    @user_email = params[:user_email]
    @collection = Collection.find(params[:id])
    host = "https://vault.library.uvic.ca"
    @downloadable = ActiveModel::Type::Boolean.new.cast(params[:downloadable])# "true" => true
    @url = "#{host}/collections/#{@collection.id}"
    puts @url
    # Send email
    mail(to: @user_email, subject: 'Job Completed')
  end

end
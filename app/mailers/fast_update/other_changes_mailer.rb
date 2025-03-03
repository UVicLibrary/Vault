class FastUpdate::OtherChangesMailer < ActionMailer::Base

  def notify_user
    email = ENV.fetch('FAST_UPDATE_OTHER_CHANGES_EMAIL', Hyrax.config.contact_email)
    @changes = params[:changes]
    mail(to: email, subject: "FASTChanges need attention")
  end

end

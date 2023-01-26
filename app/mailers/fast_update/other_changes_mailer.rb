class FastUpdate::OtherChangesMailer < ActionMailer::Base

  def notify_user
    email = Settings.fast_update.other_changes_email
    @changes = params[:changes]
    mail(to: email, subject: "FASTChanges need attention")
  end

end

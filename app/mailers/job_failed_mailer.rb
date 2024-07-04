# frozen_string_literal: true
#
# Emails an admin user when automated background jobs fail.
# To call it, pass a user email, array of ids, and the job class.
# Example of calling from a job:
# ::JobFailerMailer.call(failures: [id], job_class: self.class)
class JobFailedMailer < ActionMailer::Base

  # @param[String] user email - the email of the user to contact
  # @param[Array <String>] failures - a list of IDs that failed
  # @param [Class] - the job class, e.g. AuditBatchExportJob
  def mail_failures(params)
    @user_email = (ENV['JOB_FAILED_USER_EMAIL'] || Settings.fixity_email)
    @failures = params[:failures]
    job_class = (params[:job_class] || "" )
    mail(to: @user_email, subject: "#{job_class} Failed")
  end

  def fixity_failures(params)
    @file_sets = params[:file_sets]
    # Get a user email from config
    user_email = (ENV['JOB_FAILED_USER_EMAIL'] || Settings.fixity_email)
    mail(to: user_email, subject: "Fixity Check - Possible Corrupted Files")
  end

end
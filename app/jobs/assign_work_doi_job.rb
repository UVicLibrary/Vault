class AssignWorkDOIJob < ActiveJob::Base
  # TO DO: Once upgraded to Rails 6, we can specify the number of retries per job via
  # sidekiq_options, ActiveJob's retry_on or rescue_from, or sidekiq_retry_in
  # (see the Error Handling page on Sidekiq Github wiki)

  # Mint a new DOI for newly uploaded works
  def perform(work)
    work.reload if !work.new_record?
    return if work.doi.present?
    work.doi_status_when_public = "findable"
    work.to_controlled_vocab
    VaultDispatcher.for(:datacite).assign_for!(object: work)
    # When an error is a flaky connection error (e.g. Net::ReadTimeout, Net::OpenTimeout,
    # Blacklight::Exceptions::ECONNREFUSED, Errno::ECONNRESET, Faraday::TimeoutError), we want
    # to retry it as usual. However, for metadata errors, we want to send an email instead of
    # retrying to avoid making tons of draft DOIs.
  rescue Hyrax::DOI::Error, EdtfDateService::InvalidEdtfDateError, Hyrax::DOI::DataCiteClient::Error => e
    JobFailedMailer.mail_failures(failures: [work.id], job_class: self.class).deliver
  end

end
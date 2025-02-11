# OVERRIDE Hyrax 4.0
#   - Check fixity log files for failed ids (instead of the Hyrax default)
#   - Humanize the datetime of last fixity check
module FixityStatusPresenterDecorator

  # Returns a html_safe string communicating fixity status checks,
  # possibly on multiple files/versions.
  def render_file_set_status
    last_fixity_date = ActiveFedora::Base.find(@file_set_id).last_fixity_check

    # If a file set fails a fixity check, its ID is written to a
    # log file named with the datetime of the check
    log_path = File.join(BatchExport::FixityCheckJob::LOG_DIR, "#{last_fixity_date}.log")

    @file_set_status ||=
      if last_fixity_date.present?
        if File.exist?(log_path) && File.read(log_path).include?(@file_set_id)
          content_tag("span", "FAILED", class: "badge badge-danger") + ' ' + "on #{humanize_datetime(last_fixity_date)}"
        elsif File.exist?(log_path)
          content_tag("span", "passed", class: "badge badge-success") + ' ' + "on #{humanize_datetime(last_fixity_date)}"
        else
          content_tag("span", "unknown", class: "badge badge-warning") + ' ' + "Fixity checks have been run but Hyrax cannot find the status. This usually means the file passed but the log has been deleted."
        end
      else
        "Fixity checks have not yet been run on this object"
      end
  end

  private

  def humanize_datetime(datetime)
    DateTime.parse(datetime).to_formatted_s(:long).rpartition(' ').insert(1, " at").join
  end

end
Hyrax::FixityStatusPresenter.prepend(FixityStatusPresenterDecorator)
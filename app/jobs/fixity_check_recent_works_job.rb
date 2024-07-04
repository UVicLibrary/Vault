class FixityCheckRecentWorksJob < ActiveJob::Base

  # Enqueue fixity checks for works created 2-5 months ago. This job runs every 3 months.

  # @param [Date] start_date a DateTime object
  # @param [Date] end_date a DateTime object
  def perform(start_date = six_months_ago, end_date = three_months_ago)
    # Run fixity checks
    FixityCheckJob.perform_later(get_work_ids(start_date, end_date))
  end

  private

    # @return a DateTime object in Solr format
    def six_months_ago
      (Date.today.beginning_of_month - 7.months).midnight.strftime("%FT%H:%M:%SZ")
    end

    # @return a DateTime object in Solr format
    def three_months_ago
      (Date.today.beginning_of_month - 4.months).midnight.strftime("%FT%H:%M:%SZ")
    end

    # @return [Array < GenericWork >] array of works to pass to fixity check
    def get_work_ids(start_date, end_date)
      # AccountElevator.switch! "vault.library.uvic.ca"
      solr = RSolr.connect url: Blacklight.connection_config[:url]
      response = solr.get 'select', params: {
          q: "*:*",
          # Restrict this to non-private works because those are test objects
          fq: ["has_model_ssim:GenericWork","system_create_dtsi:[#{start_date} TO #{end_date}}"],
          rows: 5000,
          fl: "id"
      }
      response['response']['docs'].map { |doc| doc['id'] }
    end
end

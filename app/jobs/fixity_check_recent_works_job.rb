class FixityCheckRecentWorksJob < ActiveJob::Base

  # Enqueue fixity checks for works created 3-6 months ago. This job runs every 3 months.

  # @param [Date] start_date a DateTime object
  # @param [Date] end_date a DateTime object
  def perform
    # Run fixity checks
    FixityCheckJob.perform_later(get_works)
  end

  private

    # @return a DateTime object
    def start_date
      (Date.today.beginning_of_month - 6.months).midnight.strftime("%FT%H:%M:%SZ")
    end

    # @return a DateTime object
    def end_date
      (Date.today.beginning_of_month - 3.months).midnight.strftime("%FT%H:%M:%SZ")
    end

    # @return [Array < GenericWork >] array of works to pass to fixity check
    def get_works
      # Get all works uploaded between the start date and end date
      solr = RSolr.connect url: Account.find_by(tenant: Apartment::Tenant.current).solr_endpoint.url
      response = solr.get 'select', params: {
          q: "*:*",
          fq: ["has_model_ssim:GenericWork","system_create_dtsi:[#{start_date} TO #{end_date}}"],
          rows: 5000,
          fl: "id"
      }
      response['response']['docs'].map { |k,_| GenericWork.find(k['id']) }
    end
end

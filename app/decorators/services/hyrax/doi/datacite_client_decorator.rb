# OVERRIDE hyrax-doi gem, branch: 'rails_hyrax_upgrade'
# Replace Faraday's deprecated :basic_auth method with
# the updated method
# https://github.com/lostisland/faraday/issues/1317
module DataCiteClientDecorator

  private

  def connection
    Faraday.new(url: base_url) do |c|
      c.request(:authorization, :basic, username, password)
      c.adapter(Faraday.default_adapter)
    end
  end

  def mds_connection
    Faraday.new(url: mds_base_url) do |c|
      c.request(:authorization, :basic, username, password)
      c.adapter(Faraday.default_adapter)
    end
  end

end
Hyrax::DOI::DataCiteClient.prepend(DataCiteClientDecorator)
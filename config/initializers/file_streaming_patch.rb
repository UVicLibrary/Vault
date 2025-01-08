# OVERRIDE ActiveFedora v. 14.0.1
# Fix 'Access Denied' for file download links and viewers.
# By default, ActiveFedora checks the connection's headers
# for the Authorization token/key. But in prod, the token is
# actually found in the connection's env's request headers.
#
# TO DO: Figure out what happens when Hyrax stops using
# ActiveFedora altogether (because valkyrization).
ActiveFedora::File::Streaming.module_eval do

  private

  # @return [String] current authorization token from Ldp::Client
  # Note ldp_source.client is an ActiveFedora::CachingConnection
  def authorization_key
    # ldp_source.client.http.headers.fetch("Authorization", nil)
    ldp_source.client.http.head.env.request_headers['Authorization']
  end

end
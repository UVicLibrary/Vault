Rails.application.config.to_prepare do
  Blacklight::Solr::Repository.class_eval do

    # TODO: Make this private after we have a way to abstract admin/luke and ping
    # @see [RSolr::Client#send_and_receive]
    # @overload find(solr_path, params)
    #   Execute a solr query at the given path with the parameters
    #   @param [String] solr path (defaults to blacklight_config.solr_path)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @overload find(params)
    #   @param [Hash] parameters for RSolr::Client#send_and_receive
    # @return [Blacklight::Solr::Response] the solr response object
    def send_and_receive(path, solr_params = {})
      benchmark("Solr fetch", level: :debug) do
        key = blacklight_config.http_method == :post ? :data : :params
        res = connection.send_and_receive(path, {key=>solr_params.to_hash, method: blacklight_config.http_method})

        solr_response = blacklight_config.response_model.new(res, solr_params, document_model: blacklight_config.document_model, blacklight_config: blacklight_config)
        Blacklight.logger.debug("Solr query: #{blacklight_config.http_method} #{path} #{solr_params.to_hash.inspect}")
        Blacklight.logger.debug("Solr response: #{solr_response.inspect}") if defined?(::BLACKLIGHT_VERBOSE_LOGGING) and ::BLACKLIGHT_VERBOSE_LOGGING
        solr_response
      rescue Errno::ECONNREFUSED => e
        raise Blacklight::Exceptions::ECONNREFUSED, "Unable to connect to Solr instance using #{connection.inspect}: #{e.inspect}"
      rescue RSolr::Error::Http => e
        raise Blacklight::Exceptions::InvalidRequest, e.message
      end
    end

  end
end
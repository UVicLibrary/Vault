# frozen_string_literal: true

module Hydra::Derivatives::Processors
  # Extract the full text from the content using Solr's extract handler
  class FullText < Processor
    # Run the full text extraction and save the result
    # @return [TrueClass,FalseClass] was the process successful.
    def process
      output_file_service.call(extract, directives)
    end

    private

    ##
    # Extract full text from the content using Solr's extract handler.
    # This will extract text from the file
    #
    # @return [String] The extracted text
    def extract
    # Normally this uses Apache Tika to run OCR and text extraction
    # on a PDF. But sometimes if there's a lot of text, the job fails with
    # EOFError: End of file reached. We use poppler-utils' pdftotext
    # as a fallback since most PDFs we upload have been OCR'ed and
    # we just need to extract the text.
        text = fetch
        if text.class == Hash
          text["txt_file"].rstrip
        else
          JSON.parse(text)[''].rstrip
        end
    end

    # send the request to the extract service and return the response if it was successful.
    # TODO: this pulls the whole file into memory. We should stream it from Fedora instead
    # @return [String] the result of calling the extract service
    def fetch
        resp = http_request_or_read_locally
        # If this is a string, then the request failed and we used poppler instead
        if resp.class == String
          { "txt_file" => resp } # Return a hash so we can differentiate it from a resp.body
        else
          raise "Solr Extract service was unsuccessful. '#{uri}' returned code #{resp.code} for #{source_path}\n#{resp.body}" unless resp.code == '200'

          file_content.rewind if file_content.respond_to?(:rewind)
          resp.body.force_encoding(resp.type_params['charset']) if resp.type_params['charset']
          resp.body
        end
    end

    # Send the request to the extract service
    # @return [Net::HttpResponse] the result of calling the extract service
    def http_request_or_read_locally
      text = read_from_local
      # text over this limit causes connection problems with Solr, which can cause a cascade
      # of failed uploads elsewhere. Assuming any pdf with this many characters has already been
      # OCR'ed, let's just use poppler-utils to convert the pdf into a txt file and return the
      # extracted text.
      return text if text.length > 1000000
      Net::HTTP.start(uri.host, uri.port, use_ssl: check_for_ssl, read_timeout: 2000, open_timeout: 2000) do |http|
        req = Net::HTTP::Post.new(uri.request_uri, request_headers)
        req.basic_auth uri.user, uri.password unless uri.password.nil?
        req.body = file_content
        http.request req
      end
    end

    # Use poppler-utils to extract text from the local file
    # @return [String] The extracted text
    def read_from_local
      if system "pdftocairo -v"
        `pdftotext #{source_path} /cache/tmp/#{File.basename(source_path, '.pdf')}.txt`
        File.open("/cache/tmp/#{File.basename(source_path, '.pdf')}.txt").read.rstrip
      else
        raise "Poppler utils is not installed"
      end
    end

    def file_content
      @file_content ||= File.open(source_path).read
    end

    # @return [Hash] the request headers to send to the Solr extract service
    def request_headers
      { Faraday::Request::UrlEncoded::CONTENT_TYPE => mime_type.to_s,
        Faraday::Adapter::CONTENT_LENGTH => original_size.to_s }
    end

    def mime_type
      Hydra::Derivatives::MimeTypeService.mime_type(source_path)
    end

    def original_size
      File.size(source_path)
    end

    # @returns [URI] path to the extract service
    def uri
      @uri ||= connection_url + 'update/extract?extractOnly=true&wt=json&extractFormat=text'
    end

    def check_for_ssl
      uri.scheme == 'https'
    end

    # @returns [URI] path to the solr collection
    def connection_url
      ActiveFedora::SolrService.instance.conn.uri
    end
  end
end
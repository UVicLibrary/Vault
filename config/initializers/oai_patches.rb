# Fix the OAI gem resource identifier format
# See: https://github.com/code4lib/ruby-oai/issues/38

Rails.application.config.to_prepare do
  OAI::Provider::Response::RecordResponse.class_eval do
    private

    def identifier_for(record)
      case record['has_model_ssim'].first
      when "Collection"
        sub_url = "collections/#{record.id}"
      when "GenericWork"
        sub_url = "concern/generic_works/#{record.id}"
      end
      "https://vault.library.uvic.ca/#{sub_url}|https://vault.library.uvic.ca#{record.thumbnail_path}"
    end
  end

  OAI::Provider::Response::Base.class_eval do
    private

    def extract_identifier(id)
      id.sub("#{provider.prefix}:", '')
    end
  end
end
# Override blacklight_oai_provider v. 7.0.2
# Add link to Vault page and thumbnail link to OAI record

# Note: These changes need to be in an initializer rather than a
# decorator because they override config/initializers/oai_patches
# in the original gem.

# The original initializer was meant to fix the OAI gem
# resource identifier format
# See: https://github.com/code4lib/ruby-oai/issues/38

Rails.application.config.to_prepare do
  OAI::Provider::Response::RecordResponse.class_eval do

    private

    def data_for(record)
      @builder.metadata do
        # The Alma/Primo catalog importer needs extra identifier fields with links to object and thumbnail in Vault
        link_tag = "<dc:identifier>#{link_to_object(record)}</dc:identifier>"
        thumbnail_tag = "<dc:identifier>#{link_to_thumbnail(record)}</dc:identifier>"
        # Insert the extra xml before the closing <\/oai_dc:dc> tag to make valid markup
        @builder.target! << provider.format(requested_format).encode(provider.model, record).gsub(/<\/oai_dc:dc>/, link_tag + thumbnail_tag + '\0')
      end
    end

    def host_for_tenant
      Account.find_by(tenant: Apartment::Tenant.current)&.cname || "vault.#{Account.admin_host}"
    end

    def link_to_object(record)
      case record['has_model_ssim'].first
      when "GenericWork"
        sub_url = "concern/generic_works"
      when "Collection"
        sub_url = "collections"
      end
      "https://#{host_for_tenant}/#{sub_url}/#{record.id}"
    end

    def link_to_thumbnail(record)
      "https://#{host_for_tenant}#{record.thumbnail_path}"
    end
  end
end
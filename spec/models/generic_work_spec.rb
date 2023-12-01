RSpec.describe GenericWork do
  describe '#indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq WorkIndexer }
  end

  describe '#properties' do
    subject { described_class.properties.map(&:first).map(&:to_sym) }
    it { is_expected.to match_array([:has_model, :create_date, :modified_date,
                                     :head, :tail, :depositor, :title,
                                     :date_uploaded, :date_modified, :state,
                                     :proxy_depositor, :on_behalf_of,
                                     :arkivo_checksum, :owner, :doi,
                                     :doi_status_when_public, :alternative_title,
                                     :edition, :geographic_coverage, :coordinates,
                                     :chronological_coverage, :extent,
                                     :additional_physical_characteristics,
                                     :has_format, :physical_repository,
                                     :collection, :provenance, :provider,
                                     :sponsor, :genre, :format, :archival_item_identifier,
                                     :fonds_title, :fonds_creator, :fonds_description,
                                     :fonds_identifier, :is_referenced_by, :date_digitized,
                                     :transcript, :technical_note, :year, :label,
                                     :downloadable, :relative_path, :import_url,
                                     :creator, :part_of, :resource_type, :contributor,
                                     :description, :keyword, :license, :rights_statement,
                                     :publisher, :date_created, :subject, :language,
                                     :identifier, :based_near, :related_url,
                                     :bibliographic_citation, :source]) }
  end
end

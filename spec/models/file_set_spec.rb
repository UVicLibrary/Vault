require 'rails_helper'

RSpec.describe FileSet do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq FileSetIndexer }
  end

  describe '#properties' do
    subject { described_class.properties.map(&:first).map(&:to_sym) }

    it { is_expected.to match_array([:has_model, :create_date, :modified_date,
                                     :creator, :alternative_title, :edition,
                                     :geographic_coverage, :coordinates,
                                     :chronological_coverage, :extent,
                                     :additional_physical_characteristics,
                                     :has_format, :physical_repository, :provenance,
                                     :provider, :sponsor, :genre, :format,
                                     :is_referenced_by, :date_digitized, :transcript,
                                     :technical_note, :year, :head, :tail,
                                     :depositor, :title, :date_uploaded,
                                     :date_modified, :label, :last_fixity_check,
                                     :downloadable, :relative_path, :import_url,
                                     :part_of, :resource_type, :contributor,
                                     :description, :keyword, :license,
                                     :rights_statement, :publisher, :date_created,
                                     :subject, :language, :identifier, :based_near,
                                     :related_url, :bibliographic_citation, :source,
                                     :abstract, :access_right, :rights_notes]) }
  end
end

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
                                     :relative_path, :import_url, :resource_type,
                                     :contributor, :description, :keyword, :license,
                                     :rights_statement, :publisher, :date_created,
                                     :subject, :language, :identifier, :based_near,
                                     :bibliographic_citation, :source]) }
  end

  describe 'included and excluded modules' do
    subject { described_class }
    it { is_expected.not_to include Hyrax::BasicMetadata }
    it { is_expected.to include VaultBasicMetadata }
  end
end

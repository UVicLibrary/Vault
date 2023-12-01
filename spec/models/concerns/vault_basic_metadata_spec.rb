RSpec.describe VaultBasicMetadata do

  # Most properties are defined and tested in respective model specs
  # (file_set, generic_work, collection), so we don't concern
  # ourselves with them here. We only test for controlled properties
  # and #to_controlled_vocab.

  describe '#controlled_properties' do
    it 'returns the expected properties' do
      expect([GenericWork.controlled_properties,
              Collection.controlled_properties,
              FileSet.controlled_properties]).to all(contain_exactly(:based_near,
                                                                    :creator,
                                                                    :contributor,
                                                                    :physical_repository,
                                                                    :provider,
                                                                    :subject,
                                                                    :geographic_coverage,
                                                                    :genre))
    end
  end

  describe '#to_controlled_vocab' do
    let(:work) { GenericWork.new(provider: ['http://id.worldcat.org/fast/12577'],
                                 geographic_coverage: ['https://id.worldcat.org/fast/1330643'],
                                 genre: ['http://vocab.getty.edu/aat/300428443'],
                                 based_near: ['http://www.geonames.org/3181913']) }

    it 'converts http strings to instances of Hyrax::ControlledVocabularies::FieldName' do
      work.to_controlled_vocab
      expect(work.provider.first).to be_an_instance_of(Hyrax::ControlledVocabularies::Provider)
      expect(work.provider.first.id).to eq 'http://id.worldcat.org/fast/12577'
      expect(work.geographic_coverage.first).to be_an_instance_of(Hyrax::ControlledVocabularies::GeographicCoverage)
      expect(work.geographic_coverage.first.id).to eq 'https://id.worldcat.org/fast/1330643'
      expect(work.genre.first).to be_an_instance_of(Hyrax::ControlledVocabularies::Genre)
      expect(work.genre.first.id).to eq 'http://vocab.getty.edu/aat/300428443'
      expect(work.based_near.first).to be_an_instance_of(Hyrax::ControlledVocabularies::Location)
      expect(work.based_near.first.id).to eq 'http://www.geonames.org/3181913'
    end
  end

end
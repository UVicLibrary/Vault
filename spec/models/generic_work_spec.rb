RSpec.describe GenericWork do
  describe '#indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq GenericWorkIndexer }
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
                                     :relative_path, :import_url,
                                     :creator, :part_of, :resource_type, :contributor,
                                     :description, :keyword, :license, :rights_statement,
                                     :publisher, :date_created, :subject, :language,
                                     :identifier, :based_near, :related_url,
                                     :bibliographic_citation, :source]) }
  end

  let(:work) { create(:public_generic_work, doi_status_when_public: "findable", doi: ["10.1234/fake-doi"]) }

  before { allow(Hyrax::DOI::RegisterDOIJob).to receive(:perform_now).with(any_args) }

  describe '#delist_doi' do
    it "changes the work DOI's status to registered" do
      expect(Hyrax::DOI::RegisterDOIJob).to receive(:perform_now)
                                                .with(work,
                                                      registrar: work.doi_registrar.presence,
                                                      registrar_opts: work.doi_registrar_opts)
      work.delist_doi
      expect(work.reload.doi_status_when_public).to eq "registered"
    end
  end

  describe '#destroy' do

    context 'when work meets all conditions for delisting doi' do
      it 'delists the DOI' do
        expect(work).to receive(:delist_doi)
        work.destroy!
      end
    end

    context 'when work does not meet conditions' do
      before { work.visibility = "restricted" }

      it 'does not try to delist the DOI' do
        expect(work).not_to receive(:doi_status_when_public=)
        expect(work).not_to receive(:save!)
        expect(Hyrax::DOI::RegisterDOIJob).not_to receive(:perform_now)
                                                  .with(work,
                                                        registrar: work.doi_registrar.presence,
                                                        registrar_opts: work.doi_registrar_opts)
        work.destroy!
      end
    end

  end
end

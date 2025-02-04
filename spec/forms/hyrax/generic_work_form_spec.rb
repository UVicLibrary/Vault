require_relative 'shared_examples_spec'

# Generated via
#  `rails generate curation_concerns:work GenericWork`
RSpec.describe Hyrax::GenericWorkForm do

  let(:work) { GenericWork.new }
  let(:form) { described_class.new(work, nil, controller) }
  let(:controller) { instance_double(Hyrax::GenericWorksController) }
  let(:works) { [GenericWork.new, FileSet.new, GenericWork.new] }

  it_behaves_like('a Hyrax work form')

  describe "#required_fields" do
    subject { form.required_fields }

    it { is_expected.to eq [:title, :rights_statement, :provider] }
  end

  describe "#primary_terms" do
    subject { form.primary_terms }

    it { is_expected.to eq [:title, :rights_statement, :provider, :license] }
  end

  describe "#secondary_terms" do
    subject { form.secondary_terms }

    it do
      is_expected.not_to include(:title, :visibilty, :visibility_during_embargo,
                                 :embargo_release_date, :visibility_after_embargo,
                                 :visibility_during_lease, :lease_expiration_date,
                                 :visibility_after_lease, :collection_ids)

      is_expected.to eq [:alternative_title, :creator, :contributor, :description,
                         :keyword, :publisher, :date_created, :subject, :language,
                         :identifier, :based_near, :related_url, :source,
                         :resource_type, :edition, :geographic_coverage, :coordinates,
                         :chronological_coverage, :extent,
                         :additional_physical_characteristics, :has_format,
                         :physical_repository, :collection, :provenance, :sponsor,
                         :genre, :format, :archival_item_identifier, :fonds_title,
                         :fonds_creator, :fonds_description, :fonds_identifier,
                         :is_referenced_by, :date_digitized, :transcript,
                         :technical_note, :year]
    end
  end

  describe "#terms" do
    subject { form.terms }

    it { is_expected.to eq [:title, :alternative_title, :creator, :contributor,
                            :description, :keyword, :license, :rights_statement,
                            :publisher, :date_created, :subject, :language, :identifier,
                            :based_near, :related_url, :representative_id, :thumbnail_id,
                            :rendering_ids, :files, :visibility_during_embargo,
                            :embargo_release_date, :visibility_after_embargo,
                            :visibility_during_lease, :lease_expiration_date, :visibility_after_lease,
                            :visibility, :ordered_member_ids, :source, :in_works_ids,
                            :member_of_collection_ids, :admin_set_id,
                            :doi, :doi_status_when_public, :resource_type,
                            :edition, :geographic_coverage, :coordinates,
                            :chronological_coverage, :extent,
                            :additional_physical_characteristics, :has_format,
                            :physical_repository, :collection, :provenance,
                            :provider, :sponsor, :genre, :format, :archival_item_identifier,
                            :fonds_title, :fonds_creator, :fonds_description,
                            :fonds_identifier, :is_referenced_by, :date_digitized,
                            :transcript, :technical_note, :year] }
  end

  describe '.model_attributes' do
    let(:permission_template) { create(:permission_template, source_id: source_id) }
    let!(:workflow) { create(:workflow, active: true, permission_template_id: permission_template.id) }
    let(:source_id) { '123' }
    let(:file_set) { create(:file_set) }
    let(:params) do
      ActionController::Parameters.new(
          title: ['foo'],
          description: [''],
          visibility: 'open',
          source_id: source_id,
          representative_id: '456',
          rendering_ids: [file_set.id],
          thumbnail_id: '789',
          keyword: ['penguin'],
          license: ['http://creativecommons.org/licenses/by/3.0/us/'],
          member_of_collection_ids: ['123456', 'abcdef']
      )
    end

    subject { described_class.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
      expect(subject['license']).to eq ['http://creativecommons.org/licenses/by/3.0/us/']
      expect(subject['keyword']).to eq ['penguin']
      expect(subject['member_of_collection_ids']).to eq ['123456', 'abcdef']
      expect(subject['rendering_ids']).to eq [file_set.id]
    end

    context '.model_attributes' do
      let(:params) do
        ActionController::Parameters.new(
            title: [''],
            description: [''],
            keyword: [''],
            license: [''],
            member_of_collection_ids: [''],
            on_behalf_of: 'Melissa'
        )
      end

      it 'removes blank parameters' do
        expect(subject['title']).to be_empty
        expect(subject['description']).to be_empty
        expect(subject['license']).to be_empty
        expect(subject['keyword']).to be_empty
        expect(subject['member_of_collection_ids']).to be_empty
        expect(subject['on_behalf_of']).to eq 'Melissa'
      end
    end
  end

end

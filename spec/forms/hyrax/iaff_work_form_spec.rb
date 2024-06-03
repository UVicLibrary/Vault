require_relative 'shared_examples_spec'

# Generated via
#  `rails generate hyrax:work IaffWork`
RSpec.describe Hyrax::IaffWorkForm do

  let(:work) { IaffWork.new }
  let(:form) { described_class.new(work, nil, controller) }
  let(:works) { [IaffWork.new, FileSet.new, IaffWork.new] }
  let(:controller) { instance_double(Hyrax::IaffWorksController) }

  it_behaves_like('a Hyrax work form')

  describe "#required_fields" do
    subject { form.required_fields }

    it { is_expected.to eq [:title, :rights_statement, :date_created,
                            :description, :provider, :genre] }
  end

  describe "#terms" do
    subject { form.terms }

    it { is_expected.to eq [:title, :creator, :contributor, :description,
                            :keyword, :rights_statement, :publisher,
                            :date_created, :subject, :language, :identifier,
                            :based_near, :related_url, :representative_id,
                            :thumbnail_id, :rendering_ids, :files,
                            :visibility_during_embargo, :embargo_release_date,
                            :visibility_after_embargo, :visibility_during_lease,
                            :lease_expiration_date, :visibility_after_lease,
                            :visibility, :ordered_member_ids, :in_works_ids,
                            :member_of_collection_ids, :admin_set_id,
                            :provider, :genre, :geographic_coverage,
                            :provenance, :type_of_resource, :coordinates,
                            :gps_or_est, :year, :date_digitized, :technical_note]
    }
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
          member_of_collection_ids: ['123456', 'abcdef']
      )
    end

    subject { described_class.model_attributes(params) }

    it 'permits parameters' do
      expect(subject['title']).to eq ['foo']
      expect(subject['description']).to be_empty
      expect(subject['visibility']).to eq 'open'
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
            member_of_collection_ids: [''],
            on_behalf_of: 'Melissa'
        )
      end

      it 'removes blank parameters' do
        expect(subject['title']).to be_empty
        expect(subject['description']).to be_empty
        expect(subject['keyword']).to be_empty
        expect(subject['member_of_collection_ids']).to be_empty
        expect(subject['on_behalf_of']).to eq 'Melissa'
      end
    end
  end
end
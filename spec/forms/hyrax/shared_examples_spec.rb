RSpec.shared_examples "a Hyrax work form" do

  # The following variables must be defined in your work form spec:
  # works, work, controller, form
  # see spec/forms/hyrax/forms/generic_work_form.rb for an example

  describe "#version" do
    before do
      allow(work).to receive(:etag).and_return('123456')
    end
    subject { form.version }

    it { is_expected.to eq '123456' }
  end

  describe '#in_works_ids' do
    let(:work)   { parent.members.first }
    let(:parent) { FactoryBot.create(:work_with_one_child) }

    it 'gives the ids for parent works' do
      expect(form.in_works_ids).to contain_exactly(parent.id)
    end
  end

  describe "#select_files" do
    let(:work) { create(:work_with_one_file) }
    let(:title) { work.file_sets.first.title.first }
    let(:file_id) { work.file_sets.first.id }

    subject { form.select_files }

    it { is_expected.to eq(title => file_id) }
  end

  describe '#member_of_collections' do
    subject { form.member_of_collections }

    before do
      allow(controller).to receive(:params).and_return(add_works_to_collection: collection_id)
    end

    context 'when passed nil' do
      let(:collection_id) { nil }

      it { is_expected.to be_empty }
    end

    context 'when passed a string' do
      let(:collection) { create(:collection) }
      let(:collection_id) { collection.id }

      it { is_expected.to match_array([collection]) }
    end

    context 'when member of other collections' do
      let(:collection) { create(:collection) }
      let(:collection_id) { collection.id }

      before do
        allow(work).to receive(:member_of_collections).and_return(['foo'])
      end

      it { is_expected.to match_array(['foo', collection]) }
    end
  end

  describe "#[]" do
    it 'has one element' do
      expect(form['description']).to eq ['']
    end
  end

  describe "#work_members" do
    subject { form.work_members }

    before do
      allow(work).to receive(:members).and_return(works)
    end

    it "expects members that are works" do
      expect(form.work_members.size).to eq(2)
    end
  end

  describe ".build_permitted_params" do
    subject { described_class.build_permitted_params }

    context "without mediated deposit" do
      it {
        is_expected.to include(:add_works_to_collection,
                               :version,
                               :on_behalf_of,
                               { permissions_attributes: [:type, :name, :access, :id, :_destroy] },
                               { file_set: [:visibility, :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo,
                                            :visibility_during_lease, :lease_expiration_date, :visibility_after_lease, :uploaded_file_id] },
                               based_near_attributes: [:id, :_destroy],
                               member_of_collections_attributes: [:id, :_destroy],
                               work_members_attributes: [:id, :_destroy])
      }
    end
  end

  describe "initialized fields" do
    context "for :description" do
      subject { form[:description] }

      it { is_expected.to eq [''] }
    end

    context "for :embargo_release_date" do
      subject { form[:embargo_release_date] }

      it { is_expected.to be nil }
    end
  end

  describe '#visibility' do
    subject { form.visibility }

    it { is_expected.to eq 'restricted' }
  end

  describe "#open_access?" do
    subject { form.open_access? }

    it { is_expected.to be false }
  end

  describe "#authenticated_only_access?" do
    subject { form.authenticated_only_access? }

    it { is_expected.to be false }
  end

  describe "#open_access_with_embargo_release_date?" do
    subject { form.open_access_with_embargo_release_date? }

    it { is_expected.to be false }
  end

  describe "#private_access?" do
    subject { form.private_access? }

    it { is_expected.to be true }
  end

  describe "#member_ids" do
    subject { form.member_ids }

    it { is_expected.to eq work.member_ids }
  end

  describe '#display_additional_fields?' do
    subject { form.display_additional_fields? }

    context 'with no secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([])
      end
      it { is_expected.to be false }
    end
    context 'with secondary terms' do
      before do
        allow(form).to receive(:secondary_terms).and_return([:foo, :bar])
      end
      it { is_expected.to be true }
    end
  end

  describe "#embargo_release_date" do
    let(:work) { create(:work, embargo_release_date: 5.days.from_now) }

    subject { form.embargo_release_date }

    it { is_expected.to eq work.embargo_release_date }
  end

  describe "#visibility_during_embargo" do
    let(:work) { create(:work, visibility_during_embargo: 'authenticated') }

    subject { form.visibility_during_embargo }

    it { is_expected.to eq work.visibility_during_embargo }
  end

  describe "#visibility_after_embargo" do
    let(:work) { create(:work, visibility_after_embargo: 'public') }

    subject { form.visibility_after_embargo }

    it { is_expected.to eq work.visibility_after_embargo }
  end

  describe "#lease_expiration_date" do
    let(:work) { create(:work, lease_expiration_date: 2.days.from_now) }

    subject { form.lease_expiration_date }

    it { is_expected.to eq work.lease_expiration_date }
  end

  describe "#visibility_during_lease" do
    let(:work) { create(:work, visibility_during_lease: 'authenticated') }

    subject { form.visibility_during_lease }

    it { is_expected.to eq work.visibility_during_lease }
  end

  describe "#visibility_after_lease" do
    let(:work) { create(:work, visibility_after_lease: 'private') }

    subject { form.visibility_after_lease }

    it { is_expected.to eq work.visibility_after_lease }
  end

  describe ".workflow_for" do
    subject { described_class.send(:workflow_for, admin_set_id: admin_set.id) }

    context "when a active workflow is not found" do
      let(:admin_set) { create(:admin_set, with_permission_template: true) }

      it "raises a custom error" do
        expect { subject }.to raise_error Hyrax::MissingWorkflowError
      end
    end
    context "when a permission_template is not found" do
      let(:admin_set) { create(:admin_set) }

      it "raises an error" do
        expect { subject }.to raise_error(/Missing permission template for AdminSet\(id:/)
      end
    end
  end

  describe "#[]" do
    subject { form[term] }

    context "for member_of_collection_ids" do
      let(:term) { :member_of_collection_ids }

      it { is_expected.to eq [] }

      context "when the model has collection ids" do
        before do
          allow(work).to receive(:member_of_collection_ids).and_return(['col1', 'col2'])
        end
        # This allows the edit form to show collections the work is already a member of.
        it { is_expected.to eq ['col1', 'col2'] }
      end
    end
  end

  subject { form }

  it { is_expected.to delegate_method(:on_behalf_of).to(:model) }
  it { is_expected.to delegate_method(:depositor).to(:model) }
  it { is_expected.to delegate_method(:permissions).to(:model) }

end

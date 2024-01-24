# frozen_string_literal: true

require 'cancan/matchers'

RSpec.describe Ability do
  subject { ability }

  let(:ability) { described_class.new(user) }
  let(:user) { FactoryBot.create(:user) } 

  describe 'an anonymous user' do
    let(:user) { nil }

    it { is_expected.not_to be_able_to(:manage, :all) }
  end

  describe 'an ordinary user' do
    let(:user) { FactoryBot.create(:user) }

    it { is_expected.not_to be_able_to(:manage, :all) }

    describe "#user_groups" do
      subject { ability.user_groups }

      it "does not have the uvic group or the registered group" do
        expect(subject).not_to include('uvic', 'registered')
      end

      it "does not have the admin group" do
        expect(subject).not_to include 'admin'
      end
    end
  end

  describe 'a registered user who was invited by email' do
    let(:user) do
      u = FactoryBot.create(:user)
      u.add_role(:depositor)
      u
    end

    it { is_expected.not_to be_able_to(:manage, :all) }

    describe "#user_groups" do
      subject { ability.user_groups }

      it "does not have the uvic group" do
        expect(subject).not_to include 'uvic'
      end

      it "does not have the admin group" do
        expect(subject).not_to include 'admin'
      end
    end
  end

  describe 'a uvic user' do
    let(:user) { FactoryBot.create(:uvic) }

    describe '#user_groups' do
      subject { ability.user_groups }

      it 'has the uvic group' do
        expect(subject).to include 'uvic'
      end

      it "does not have the admin group" do
        expect(subject).not_to include 'admin'
      end
    end
  end

  describe 'a user with an authorized IP address' do
    let(:ability) { described_class.new(user, remote_ip: "111.111.11.11") }

    describe '#user_groups' do
      subject { ability.user_groups }

      it 'has the uvic group' do
        expect(subject).to include 'uvic'
      end

      it "does not have the admin group" do
        expect(subject).not_to include 'admin'
      end
    end
  end

  describe 'an administrative user' do
    let(:user) { FactoryBot.create(:admin) }

    it { is_expected.not_to be_able_to(:manage, :all) }
    it { is_expected.not_to be_able_to(:manage, Account) }
    it { is_expected.to be_able_to(:manage, Site) }

    describe "#user_groups" do
      subject { ability.user_groups }

      it "has the admin group" do
        expect(subject).to include 'admin'
      end
    end
  end

  describe 'a superadmin user' do
    let(:user) { FactoryBot.create(:superadmin) }

    it { is_expected.to be_able_to(:manage, :all) }
  end

  shared_context 'with deposit access on an admin set' do
    let(:permission_template) { FactoryBot.create(:permission_template, with_admin_set: true) }

    before do
      FactoryBot.create(:permission_template_access,
                        :deposit,
                        permission_template: permission_template,
                        agent_type: 'user',
                        agent_id: user.user_key)
    end
  end

  shared_context 'with create access on a work type' do
    let(:work_model) { GenericWork }

    before { ability.can(:create, work_model) }
  end

  describe '#can_create_any_work?' do
    subject { ability.can_create_any_work? }

    it { is_expected.to eq false }

    context 'when user can deposit to an admin set' do
      include_context 'with deposit access on an admin set'

      it { is_expected.to eq false }

      context 'and user can create a work type' do
        include_context 'with create access on a work type'

        it { is_expected.to eq true }
      end
    end
  end

  describe '#editor_abilities' do
    let(:user) { FactoryBot.create(:admin) }
    before { allow(ability).to receive(:can).with(any_args).and_call_original }

    it 'includes Hyrax::SolrDocument::OrderedMembers' do
      ability.editor_abilities
      expect(ability).to have_received(:can).with(:edit, Hyrax::SolrDocument::OrderedMembers)
    end
  end

  # TO DO: Our current solr config doesn't add the required fields
  # into the permissions query to actually yield the correct results.
  # Return to this once we've had the opportunity to edit solrconfig.xml.
  describe '#download_groups' do
    let(:id) { "foo" }
    let(:doc) {
      { 'id' => id,
        'visibility_ssi' => 'open',
        'edit_access_group_ssim' => ['group1'],
        'download_access_group_ssim' => ['group2']
      }
    }
    subject { ability.download_groups(id) }

    before { allow(Account).to receive(:find_by).with(any_args).and_return(Account.new(name: 'vault')) }
    before { allow(SolrDocument).to receive(:find).with('foo').and_return(doc) }
  end

  # TO DO: Our current solr config doesn't add the required fields
  # into the permissions query to actually yield the correct results.
  # Return to this once we've had the opportunity to edit solrconfig.xml.
  describe 'download_users' do
    let(:id) { "foo" }
    let(:doc) {
      { 'id' => id,
        'visibility_ssi' => 'open',
        'edit_access_person_ssim' => ['user1'],
        'download_access_person_ssim' => ['user2']
      }
    }

    subject { ability.download_users(id) }
    before { allow(SolrDocument).to receive(:find).with('foo').and_return(doc) }

    it 'includes download and edit users' do
      expect(subject).to include "user1"
      expect(subject).to include "user2"
    end
  end

  context 'with a WorkShowPresenter' do
    # we want to stub the object under test here, because we want to ensure it
    # is calling another method on itself to resolve these authorizations
    # rubocop:disable RSpec/SubjectStub
    let(:attributes)    { { id: 'my_solr_doc_id' } }
    let(:presenter)     { Hyrax::WorkShowPresenter.new(solr_document, ability, :NULL_REQUEST) }
    let(:solr_document) { SolrDocument.new(attributes) }

    describe 'can?(:edit)' do
      it 'defers strictly to the presenter solr_document ' do
        expect(ability)
            .to receive(:test_edit)
                    .with('my_solr_doc_id')
                    .and_return(true)

        expect(ability.can?(:edit, presenter)).to eq true
      end
    end
    # rubocop:enable RSpec/SubjectStub
  end
end

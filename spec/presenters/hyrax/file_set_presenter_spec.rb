# frozen_string_literal: true
require 'iiif_manifest'

# rubocop:disable RSpec/SubjectStub
RSpec.describe Hyrax::FileSetPresenter do
  subject(:presenter) { described_class.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:ability) { Ability.new(user) }
  let(:attributes) { file.to_solr }

  let(:file) do
    build(:file_set,
          id: '123abc',
          user: user,
          title: ["File title"],
          depositor: user.user_key,
          label: "filename.tif")
  end
  let(:user) { create(:admin) }

  describe 'stats_path' do
    before do
      # https://github.com/samvera/active_fedora/issues/1251
      allow(file).to receive(:persisted?).and_return(true)
      allow(ActiveFedora::Base).to receive(:find).with(file.id).and_return(file)
      allow(FileSet).to receive(:find).with(file.id).and_return(file)
    end
    it { expect(presenter.stats_path).to eq Hyrax::Engine.routes.url_helpers.stats_file_path(id: file.id, locale: 'en') }
  end

  describe "#to_s" do
    subject { presenter.to_s }

    it { is_expected.to eq 'File title' }
  end

  describe "#human_readable_type" do
    subject { presenter.human_readable_type }

    it { is_expected.to eq 'File' }
  end

  describe "#model_name" do
    subject { presenter.model_name }

    it { is_expected.to be_kind_of ActiveModel::Name }
  end

  describe "#to_partial_path" do
    subject { presenter.to_partial_path }

    it { is_expected.to eq 'file_sets/file_set' }
  end

  describe "office_document?" do
    subject { presenter.office_document? }

    it { is_expected.to be false }
  end

  describe "#user_can_perform_any_action?" do
    subject { presenter.user_can_perform_any_action? }
    let(:current_ability) { ability }
    let(:parent_presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new, ability) }

    before do
      allow(presenter).to receive(:parent).and_return(parent_presenter)
    end

    context 'when user can perform at least 1 action' do
      before do
        expect(current_ability).to receive(:can?).with(:edit, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:destroy, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:download, presenter.id).and_return true
      end

      it { is_expected.to be true }

      it 'is deprecated' do
        expect(Deprecation).to receive(:warn)
        subject
      end

    end
    context 'when user cannot perform any action' do
      before do
        expect(current_ability).to receive(:can?).with(:edit, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:destroy, presenter.id).and_return false
        expect(current_ability).to receive(:can?).with(:download, presenter.id).and_return false
      end

      it { is_expected.to be false }
    end
  end

  describe "properties delegated to solr_document" do
    let(:solr_properties) do
      ["date_uploaded", "title_or_label",
       "contributor", "creator", "title", "description", "publisher",
       "subject", "language", "license", "format_label", "file_size",
       "height", "width", "filename", "well_formed", "page_count",
       "file_title", "last_modified", "original_checksum", "mime_type",
       "duration", "sample_rate", "alpha_channels", "original_file_id"]
    end

    it "delegates to the solr_document" do
      solr_properties.each do |property|
        expect(solr_document).to receive(property.to_sym)
        presenter.send(property)
      end
    end
    it { is_expected.to delegate_method(:depositor).to(:solr_document) }
    it { is_expected.to delegate_method(:keyword).to(:solr_document) }
    it { is_expected.to delegate_method(:date_created).to(:solr_document) }
    it { is_expected.to delegate_method(:date_modified).to(:solr_document) }
    it { is_expected.to delegate_method(:itemtype).to(:solr_document) }
    it { is_expected.to delegate_method(:fetch).to(:solr_document) }
    it { is_expected.to delegate_method(:first).to(:solr_document) }
    it { is_expected.to delegate_method(:has?).to(:solr_document) }
  end

  describe '#link_name' do
    context "with a user who can view the file" do
      before do
        allow(ability).to receive(:can?).with(:read, "123abc").and_return(true)
      end
      it "shows the title" do
        expect(presenter.link_name).to eq 'File title'
        expect(presenter.link_name).not_to eq 'filename.tif'
      end
    end

    context "with a user who cannot view the file" do
      before do
        allow(ability).to receive(:can?).with(:read, "123abc").and_return(false)
      end
      it "hides the title" do
        expect(presenter.link_name).to eq 'File'
      end
    end
  end

  describe '#tweeter' do
    subject { presenter.tweeter }

    it 'delegates the depositor as the user_key to TwitterPresenter.call' do
      expect(Hyrax::TwitterPresenter).to receive(:twitter_handle_for).with(user_key: solr_document.depositor)
      subject
    end
  end

  describe "#event_class" do
    subject { presenter.event_class }

    it { is_expected.to eq 'FileSet' }
  end

  describe '#events' do
    subject(:events) { presenter.events }

    let(:event_stream) { double('event stream') }
    let(:response) { double('response') }

    before do
      allow(presenter).to receive(:event_stream).and_return(event_stream)
    end

    it 'calls the event store' do
      allow(event_stream).to receive(:fetch).with(100).and_return(response)
      expect(events).to eq response
    end
  end

  describe '#event_stream' do
    let(:object_stream) { double('object_stream') }

    it 'returns a Nest stream' do
      expect(Hyrax::RedisEventStore).to receive(:for).with(Nest).and_return(object_stream)
      presenter.send(:event_stream)
    end
  end

  describe "characterization" do
    describe "#characterization_metadata" do
      subject { presenter.characterization_metadata }

      it "only has set attributes are in the metadata" do
        expect(subject[:height]).to be_blank
        expect(subject[:page_count]).to be_blank
      end

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }

        it "only has set attributes are in the metadata" do
          expect(subject[:height]).not_to be_blank
          expect(subject[:page_count]).to be_blank
        end
      end
    end

    describe "#characterized?" do
      subject { presenter }

      it { is_expected.not_to be_characterized }

      context "when height is set" do
        let(:attributes) { { height_is: '444' } }

        it { is_expected.to be_characterized }
      end

      context "when file_format is set" do
        let(:attributes) { { file_format_tesim: ['format'] } }

        it { is_expected.to be_characterized }
      end
    end

    describe "#label_for_term" do
      subject { presenter.label_for_term(:titleized_key) }

      it { is_expected.to eq("Titleized Key") }
    end

    describe "with additional characterization metadata" do
      let(:additional_metadata) do
        {
            foo: ["bar"],
            fud: ["bars", "cars"]
        }
      end

      before { allow(presenter).to receive(:additional_characterization_metadata).and_return(additional_metadata) }
      subject { presenter }

      specify do
        expect(subject).to be_characterized
        expect(subject.characterization_metadata[:foo]).to contain_exactly("bar")
        expect(subject.characterization_metadata[:fud]).to contain_exactly("bars", "cars")
      end
    end

    describe "characterization values" do
      before { allow(presenter).to receive(:characterization_metadata).and_return(mock_metadata) }

      context "with a limited set of short values" do
        let(:mock_metadata) { { term: ["asdf", "qwer"] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("asdf", "qwer") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to be_empty }
        end
      end

      context "with a value set exceeding the configured amount" do
        let(:mock_metadata) { { term: ["1", "2", "3", "4", "5", "6", "7", "8"] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("1", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to contain_exactly("6", "7", "8") }
        end
      end

      context "with values exceeding 250 characters" do
        let(:mock_metadata) { { term: [("a" * 251), "2", "3", "4", "5", "6", ("b" * 251)] } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly(("a" * 247) + "...", "2", "3", "4", "5") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to contain_exactly("6", (("b" * 247) + "...")) }
        end
      end

      context "with a string as a value" do
        let(:mock_metadata) { { term: "string" } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("string") }
        end
        describe "#secondary_characterization_values" do
          subject { presenter.secondary_characterization_values(:term) }

          it { is_expected.to be_empty }
        end
      end

      context "with an integer as a value" do
        let(:mock_metadata) { { term: 1440 } }

        describe "#primary_characterization_values" do
          subject { presenter.primary_characterization_values(:term) }

          it { is_expected.to contain_exactly("1440") }
        end
      end
    end
  end

  describe 'IIIF integration' do
    def uri_segment_escape(uri)
      ActionDispatch::Journey::Router::Utils.escape_segment(uri)
    end

    let(:file_set) { create(:file_set) }
    let(:solr_document) { SolrDocument.new(file_set.to_solr) }
    let(:request) { double('request', base_url: 'http://test.host') }
    let(:presenter) { described_class.new(solr_document, ability, request) }
    let(:id) { Hyrax::Base.uri_to_id(file_set.original_file.versions.last.uri) }

    describe "#display_image" do
      subject { presenter.display_image }

      context 'without a file' do
        let(:id) { 'bogus' }

        it { is_expected.to be_nil }
      end

      context 'with a file' do
        before do
          Hydra::Works::AddFileToFileSet.call(file_set,
                                              file_path, :original_file)
        end

        context "when the file is not an image" do
          let(:file_path) { File.open(fixture_path + '/hyrax_generic_stub.txt') }

          it { is_expected.to be_nil }
        end

        context "when the file is an image" do
          let(:file_path) { File.open(fixture_path + '/world.png') }

          before do
            allow(solr_document).to receive(:image?).and_return(true)
            allow(ability).to receive(:can?).with(:read, solr_document).and_return true
          end

          it { is_expected.to be_instance_of IIIFManifest::DisplayImage }

          it 'has a IIIF url' do
            expect(subject.url).to eq "http://test.host/downloads/#{file_set.id}"
            # expect(subject.url).to eq "http://test.host/images/#{uri_segment_escape(id)}/full/600,/0/default.jpg"
          end

          # context 'with custom image size default' do
          #   let(:custom_image_size) { '666,' }
          #
          #   around do |example|
          #     default_image_size = Hyrax.config.iiif_image_size_default
          #     Hyrax.config.iiif_image_size_default = custom_image_size
          #     example.run
          #     Hyrax.config.iiif_image_size_default = default_image_size
          #   end
          #
          #   it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
          #   it 'has a IIIF url' do
          #     expect(subject.url).to eq "http://test.host/images/#{uri_segment_escape(id)}/full/#{custom_image_size}/0/default.jpg"
          #   end
          # end

          # context 'with custom image url builder' do
          #   let(:id) { file_set.original_file.id }
          #   let(:custom_builder) do
          #     ->(file_id, base_url, _size, _format) { "#{base_url}/downloads/#{file_id.split('/').first}" }
          #   end
          #
          #   around do |example|
          #     default_builder = Hyrax.config.iiif_image_url_builder
          #     Hyrax.config.iiif_image_url_builder = custom_builder
          #     example.run
          #     Hyrax.config.iiif_image_url_builder = default_builder
          #   end
          #
          #   it { is_expected.to be_instance_of IIIFManifest::DisplayImage }
          #   it 'has a url that includes downloads/id' do
          #     expect(subject.url).to eq "http://test.host/downloads/#{id.split('/').first}"
          #   end
          # end

          context "when the user doesn't have permission to view the image" do
            before do
              allow(ability).to receive(:can?).with(:read, solr_document).and_return false
            end

            it { is_expected.to be_nil }
          end
        end
      end
    end

    describe "#iiif_endpoint" do
      subject { presenter.send(:iiif_endpoint, id) }

      before do
        allow(Hyrax.config).to receive(:iiif_image_server?).and_return(riiif_enabled)
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            File.open(fixture_path + '/world.png'), :original_file)
      end

      context 'with iiif_image_server enabled' do
        let(:riiif_enabled) { true }

        it 'has a subject url and profile' do
          expect(subject.url).to eq "http://test.host/images/#{uri_segment_escape(id)}"
          expect(subject.profile).to eq 'http://iiif.io/api/image/2/level2.json'
        end

        context 'with a custom iiif image profile' do
          let(:custom_profile) { 'http://iiif.io/api/image/2/level1.json' }

          around do |example|
            default_profile = Hyrax.config.iiif_image_compliance_level_uri
            Hyrax.config.iiif_image_compliance_level_uri = custom_profile
            example.run
            Hyrax.config.iiif_image_compliance_level_uri = default_profile
          end

          it 'sets a custom profile' do
            expect(subject.profile).to eq custom_profile
          end
        end
      end

      context 'with iiif_image_server disabled' do
        let(:riiif_enabled) { false }

        it { is_expected.to be nil }
      end
    end
  end

  describe "#parent" do
    let(:read_permission) { true }
    let(:edit_permission) { false }
    let(:parent_work_active) do
      create(:work, :public, state: ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#active'))
    end
    let(:file_set_active) do
      create(:file_set, read_groups: ['public']).tap do |file_set|
        parent_work_active.ordered_members << file_set
        parent_work_active.save!
      end
    end
    let(:parent_work_inactive) do
      create(:work, :public, state: ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#inactive'))
    end
    let(:file_set_inactive) do
      create(:file_set, read_groups: ['public']).tap do |file_set|
        parent_work_inactive.ordered_members << file_set
        parent_work_inactive.save!
      end
    end

    describe "active parent" do
      let(:read_permission) { true }
      let(:edit_permission) { false }
      let(:solr_document) { SolrDocument.new(file_set_active.to_solr) }
      let(:solr_document_work) { SolrDocument.new(parent_work_active.to_solr) }
      let(:request) { double(base_url: 'http://test.host') }
      let(:presenter) { described_class.new(solr_document, ability, request) }

      before do
        allow(ability).to receive(:can?).with(:read, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && read_permission
        end
        allow(ability).to receive(:can?).with(:edit, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && edit_permission
        end
      end

      context "is created when parent work is active" do
        subject { presenter.parent }

        it { is_expected.not_to be_nil }
      end
    end

    describe "inactive parent" do
      let(:read_permission) { true }
      let(:edit_permission) { false }
      let(:solr_document) { SolrDocument.new(file_set_inactive.to_solr) }
      let(:solr_document_work) { SolrDocument.new(parent_work_inactive.to_solr) }
      let(:request) { double(base_url: 'http://test.host') }
      let(:presenter) { described_class.new(solr_document, ability, request) }

      before do
        allow(ability).to receive(:can?).with(:read, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && read_permission
        end
        allow(ability).to receive(:can?).with(:edit, anything) do |_read, solr_doc|
          solr_document_work.id == solr_doc.id && edit_permission
        end
      end

      context "is created when parent work is active" do
        subject { presenter.parent }
        it "raises an error" do
          expect { subject }.to raise_error(Hyrax::WorkflowAuthorizationException)
        end
      end
    end
  end
end
# rubocop:enable RSpec/SubjectStub

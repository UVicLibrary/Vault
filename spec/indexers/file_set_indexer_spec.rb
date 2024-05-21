RSpec.describe FileSetIndexer do
  include Hyrax::FactoryHelpers

  let(:file_set) do
    FileSet.new(
      id: 'foo12345',
      contributor: ['Mohammad'],
      creator: ['Allah'],
      title: ['The Work'],
      description: ['The work by Allah'],
      publisher: ['Vertigo Comics'],
      date_created: ['1200-01-01'],
      date_uploaded: Date.parse('2011-01-01'),
      date_modified: Date.parse('2012-01-01'),
      subject: ['Theology'],
      language: ['Arabic'],
      license: ['Wide open, buddy.'],
      rights_statement: ['No Known Copyright'],
      resource_type: ['Book'],
      identifier: ['urn:isbn:1234567890'],
      based_near: ['Medina, Saudi Arabia']
    )
  end

  let(:mock_file) do
    mock_file_factory(
      content: "asdf",
      digest: ["urn:sha1:f794b23c0c6fe1083d0ca8b58261a078cd968967"],
      mime_type: 'image/jpeg',
      format_label: ['JPEG Image'],
      height: ['500'],
      width: ['600'],
      file_size: ['12'],
      page_count: ['1'],
      file_title: ['title'],
      duration: ['0:1'],
      sample_rate: ['sample rate']
    )
  end

  let(:mock_text) do
    mock_file_factory(content: "abcxyz")
  end

  let(:indexer) { described_class.new(file_set) }

  describe '#generate_solr_document' do

    let(:graph) { ActiveFedora::VersionsGraph.new }

    before do
      # https://github.com/samvera/active_fedora/issues/1251
      allow(file_set).to receive(:persisted?).and_return(true)
      allow(file_set).to receive(:label).and_return('CastoriaAd.tiff')
      allow(VaultThumbnailPathService).to receive(:call).and_return("/images/1001/full/!150,300/0/default.jpg")
      allow(file_set).to receive(:original_file).and_return(mock_file)
      allow(file_set).to receive(:extracted_text).and_return(mock_text)
      allow(mock_file).to receive(:versions).and_return(graph)
      allow(graph).to receive(:all).and_return([])
    end
    subject { indexer.generate_solr_document }

    it 'has fields' do
      expect(subject['hasRelatedMediaFragment_ssim']).to eq 'foo12345'
      expect(subject['hasRelatedImage_ssim']).to eq 'foo12345'
      expect(subject['date_uploaded_tesim']).to be_nil
      expect(subject['date_modified_tesim']).to be_nil
      expect(subject['date_uploaded_dtsi']).to eq '2011-01-01T00:00:00Z'
      expect(subject['date_modified_dtsi']).to eq '2012-01-01T00:00:00Z'
      expect(subject['license_tesim']).to eq ['Wide open, buddy.']
      expect(subject['rights_statement_tesim']).to eq ['No Known Copyright']
      expect(subject['contributor_tesim']).to eq ['Mohammad']
      expect(subject['creator_tesim']).to eq ['Allah']
      expect(subject['title_tesim']).to eq ['The Work']
      expect(subject['title_sim']).to eq ['The Work']
      expect(subject['label_tesim']).to eq 'CastoriaAd.tiff'
      expect(subject['label_ssi']).to eq 'CastoriaAd.tiff'
      expect(subject['description_tesim']).to eq ['The work by Allah']
      expect(subject['publisher_tesim']).to eq ['Vertigo Comics']
      expect(subject['subject_tesim']).to eq ['Theology']
      expect(subject['language_tesim']).to eq ['Arabic']
      expect(subject['date_created_tesim']).to eq ['1200-01-01']
      expect(subject['resource_type_tesim']).to eq ['Book']
      expect(subject['file_format_tesim']).to eq 'jpeg (JPEG Image)'
      expect(subject['identifier_tesim']).to eq ['urn:isbn:1234567890']
      expect(subject['based_near_tesim']).to eq ['Medina, Saudi Arabia']
      expect(subject['mime_type_ssi']).to eq 'image/jpeg'
      expect(subject['thumbnail_path_ss']).to eq "/images/1001/full/!150,300/0/default.jpg"
      expect(subject['all_text_timv']).to eq('abcxyz')
      expect(subject['height_is']).to eq 500
      expect(subject['width_is']).to eq 600
      expect(subject['digest_ssim']).to eq 'urn:sha1:f794b23c0c6fe1083d0ca8b58261a078cd968967'
      expect(subject['visibility_ssi']).to eq 'restricted'
      expect(subject['page_count_tesim']).to eq ['1']
      expect(subject['file_title_tesim']).to eq ['title']
      expect(subject['duration_tesim']).to eq ['0:1']
      expect(subject['sample_rate_tesim']).to eq ['sample rate']
      expect(subject['current_file_version_ssi']).to eq file_set.original_file.id
    end

    context "when the file set's parent has a creator" do
      let(:work) { GenericWork.new(creator: ["http://id.worldcat.org/fast/522461/"], id: "foo") }
      let(:parent_doc) { SolrDocument.new(creator_tesim: ["http://id.worldcat.org/fast/522461/"],
                                          creator_label_tesim: ["University of Victoria (B.C.). Library"]) }

      before do
        allow(file_set).to receive(:parent).and_return(work)
        allow(SolrDocument).to receive(:find).with(work.id).and_return(parent_doc)
      end

      it "indexes the parent's creator as its own" do
        expect(subject['creator_tesim']).to eq(parent_doc['creator_tesim'])
        expect(subject['creator_label_tesim']).to eq(parent_doc['creator_label_tesim'])
      end
    end

    context "when the parent work is public and downloadable" do

      let(:work) { GenericWork.new }
      let(:permissions) do
        [ Hydra::AccessControls::Permission.new(name: "public",
                                                type: "group",
                                                access: "download"),
          Hydra::AccessControls::Permission.new(name: "user1",
                                                type: "person",
                                                access: "download")]
      end
      let(:visibility) { "restricted" }

      before do
        allow(work).to receive(:permissions).and_return(permissions)
        allow(file_set).to receive(:parent).and_return(work)
        allow(file_set).to receive(:visibility).and_return(visibility)
      end

      context 'and file set is private' do
        it "does not index the public download access group" do
          expect(subject['download_access_group_ssim']).to be_empty
          expect(subject['download_access_user_ssim']).to eq ['user1']
        end
      end

      context 'and file set is public' do
        let(:visibility) { "open" }

        it "indexes the public download access group" do
          expect(subject['download_access_group_ssim']).to eq ["public"]
          expect(subject['download_access_user_ssim']).to eq ['user1']
        end
      end

    end

    context 'with a parent with specified download permissions' do
      let(:work) { GenericWork.new }
      let(:permissions) do
        [ Hydra::AccessControls::Permission.new(name: "group1",
                                                type: "group",
                                                access: "download"),
          Hydra::AccessControls::Permission.new(name: "user1",
                                                type: "person",
                                                access: "download")]
      end

      before do
        allow(file_set).to receive(:parent).and_return(work)
        allow(work).to receive(:permissions).and_return(permissions)
      end

      it 'indexes download permissions' do
        expect(subject['download_access_group_ssim']).to eq ['group1']
        expect(subject['download_access_user_ssim']).to eq ['user1']
      end
    end
  end

  context 'with controlled vocabulary fields' do
    before do
      file_set.geographic_coverage = ["http://id.worldcat.org/fast/1243522"]
      file_set.subject = ["http://id.worldcat.org/fast/124399"]
    end

    subject { indexer.generate_solr_document }

    it 'indexes the URI and label' do
      expect(subject['geographic_coverage_tesim']).to eq(["http://id.worldcat.org/fast/1243522"])
      expect(subject['geographic_coverage_label_tesim']).to eq(["United States--Pacific Coast"])
      expect(subject['subject_tesim']).to eq(["http://id.worldcat.org/fast/124399"])
      expect(subject['subject_label_tesim']).to eq(["Hammond, Charlie, 1870-1953"])
    end
  end

  describe '#file_format' do
    subject { indexer.send(:file_format) }

    context 'when both mime and format_label are present' do
      before do
        allow(file_set).to receive(:mime_type).and_return('image/png')
        allow(file_set).to receive(:format_label).and_return(['Portable Network Graphics'])
      end
      it { is_expected.to eq 'png (Portable Network Graphics)' }
    end

    context 'when just mime type is present' do
      before do
        allow(file_set).to receive(:mime_type).and_return('image/png')
        allow(file_set).to receive(:format_label).and_return([])
      end
      it { is_expected.to eq 'png' }
    end

    context 'when just format_label is present' do
      before do
        allow(file_set).to receive(:mime_type).and_return('')
        allow(file_set).to receive(:format_label).and_return(['Portable Network Graphics'])
      end
      it { is_expected.to eq ['Portable Network Graphics'] }
    end
  end
end

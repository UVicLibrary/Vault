# frozen_string_literal: true
RSpec.describe Bolognese::Readers::GenericWorkReader do

  let(:xml) { VaultDataCiteRegistrar.new.work_to_datacite_xml(work, doi) }
  subject { Nokogiri::XML::Document.parse(xml) }

  let(:doi) { "10.9999/xxxx" }

  let(:work) {
    GenericWork.new(
        doi: [doi],
        title: ["Hardly Working"],
        create_date: Date.parse("2023-07-24"),
        # All controlled_properties fields should work with
        # URIs and literal/string values
        publisher: ["Penguin Canada"],
        resource_type: ["http://purl.org/dc/dcmitype/StillImage"]
    )
  }

  describe 'maps mandatory fields' do

    it 'inserts an existing DOI into the identifier field' do
      expect(subject.at_css('identifier').children.text).to eq "https://doi.org/10.9999/xxxx"
      expect(subject.at_css('identifier').attributes['identifierType'].value).to eq "DOI"
    end

    it 'inserts the title into the title field' do
      expect(subject.at_css('title').text).to match "Hardly Working"
    end

    describe 'creator' do
      context 'when a work has a creator' do

        let(:uri) { subject.css('creator')[0] }
        let(:string) { subject.css('creator')[1] }
        let(:creator) { [Hyrax::ControlledVocabularies::Creator.new("http://id.worldcat.org/fast/84645"),
                         "Literal creator"] }

        before { work.creator = creator }

        it 'generates the correct xml for FAST uris' do
          expect(subject.css('creator').count).to eq 2
          expect(uri.at_css('creatorName').inner_text).to eq "Ishiguro, Kazuo, 1954-"
          expect(uri.at_css('nameIdentifier').attributes['nameIdentifierScheme'].value).to eq "FAST"
          expect(uri.at_css('nameIdentifier').attributes['schemeURI'].value).to eq "http://id.worldcat.org/fast"
          expect(uri.at_css('nameIdentifier').inner_text).to eq "84645"
        end

        it 'generates the correct xml for textual values' do
          expect(subject.css('creator').count).to eq 2
          expect(string.at_css('creatorName').inner_text).to eq "Literal Creator"
        end
      end

      context "when a work has no creator" do
        it 'sets the creator to :unav (unavailable)' do
          expect(subject.css('creator').count).to eq 1
          expect(subject.css('creator')[0].at_css('creatorName').inner_text).to eq ":Unav"
        end
      end
    end

    describe 'publisher' do
      it 'sets the publisher to University of Victoria Libraries' do
        expect(subject.at_css('publisher').inner_text).to eq "University of Victoria Libraries"
      end
    end

    describe 'publication year' do
      it 'sets the publication year to be the year the work was created' do
        expect(subject.at_css('publicationYear').inner_text).to eq "2023"
      end
    end

    describe 'resource type' do
      it "sets the resource type(s) to the URI in the work's resource type" do
        expect(subject.at_css('resourceType').inner_text).to eq "Still Image"
      end

      context 'with multiple resource types' do
        before { work.resource_type = ["http://purl.org/dc/dcmitype/StillImage",
                                       "http://purl.org/dc/dcmitype/Text"] }

        it 'only uses the first one (because that is what DataCite will accept)' do
          expect(subject.css('resourceType').count).to eq 1
          expect(subject.at_css('resourceType').inner_text).to eq "Still Image"
        end
      end
    end

  end
end
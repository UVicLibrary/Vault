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

  describe 'mandatory fields' do

    it 'inserts a DOI into the identifier field' do
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
        let(:creator) { [Hyrax::ControlledVocabularies::Creator.new("https://id.worldcat.org/fast/84645"),
                         "Literal creator"] }

        before { work.creator = creator }

        it 'generates the correct xml for FAST uris' do
          expect(subject.css('creator').count).to eq 2
          expect(uri.at_css('creatorName').inner_text).to eq "Ishiguro, Kazuo, 1954-"
          expect(uri.at_css('nameIdentifier').attributes['nameIdentifierScheme'].value).to eq "FAST"
          expect(uri.at_css('nameIdentifier').attributes['schemeURI'].value).to eq "https://id.worldcat.org/fast"
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

        it 'only uses the first resource type (because DataCite only accepts 1)' do
          expect(subject.css('resourceType').count).to eq 1
          expect(subject.at_css('resourceType').inner_text).to eq "Still Image"
        end

        context 'when resourceTypeGeneral is of a known type' do
          it 'sets resourceTypeGeneral to a controlled value' do
            expect(subject.at_css('resourceType').attributes['resourceTypeGeneral'].value).to eq "Image"
          end
        end
      end

      context 'when resourceTypeGeneral is not known' do
        before { work.resource_type = ["http://purl.org/dc/dcmitype/Service"] }

        it 'sets resourceTypeGeneral to "Other"' do
            expect(subject.at_css('resourceType').attributes['resourceTypeGeneral'].value).to eq "Other"
        end
      end

      context 'when resource type is Moving Image' do
        before { work.resource_type = ["http://purl.org/dc/dcmitype/MovingImage"] }

        it 'sets resourceTypeGeneral to "Audiovisual"' do
          expect(subject.at_css('resourceType').attributes['resourceTypeGeneral'].value).to eq "Audiovisual"
          expect(subject.at_css('resourceType').inner_text).to eq "Moving Image"
        end
      end

      context 'when resource type is blank' do
        before { work.resource_type = [] }

        it 'sets the resource type to :unav' do
          expect(subject.at_css('resourceType').inner_text).to eq ":unav"
          expect(subject.at_css('resourceType').attributes['resourceTypeGeneral'].value).to eq "Other"
        end
      end
    end
  end

  describe 'recommended fields' do

    describe 'contributors' do
      context 'when work has contributors' do

        let(:uri) { subject.css('contributor')[0] }
        let(:string) { subject.css('contributor')[1] }
        let(:contributor) { [Hyrax::ControlledVocabularies::Contributor.new("https://id.worldcat.org/fast/84645"),
                         "Literal contributor"] }

        before { work.contributor = contributor }

        it 'generates the correct xml for FAST uris' do
          expect(subject.css('contributor').count).to eq 2
          expect(uri.at_css('contributorName').inner_text).to eq "Ishiguro, Kazuo, 1954-"
          expect(uri.at_css('nameIdentifier').attributes['nameIdentifierScheme'].value).to eq "FAST"
          expect(uri.at_css('nameIdentifier').attributes['schemeURI'].value).to eq "https://id.worldcat.org/fast"
          expect(uri.at_css('nameIdentifier').inner_text).to eq "84645"
        end

        it 'generates the correct xml for textual values' do
          expect(subject.css('contributor').count).to eq 2
          expect(string.at_css('contributorName').inner_text).to eq "Literal Contributor"
        end
      end

      context 'when contributors is blank' do
        it 'does not insert anything into contributor' do
          expect(subject.css('contributor').count).to be 0
        end
      end
    end

    describe 'descriptions' do

      context 'when work has description(s)' do
        let(:descr) { ["A free text description."] }
        before { work.description = descr }

        it 'generates the correct xml' do
          expect(subject.css('descriptions').count).to eq 1
          expect(subject.css('description').count).to eq 1
          expect(subject.at_css('description').inner_text).to eq "A free text description."
          expect(subject.at_css('description').attributes['descriptionType'].value).to eq "Abstract"
        end

        context 'with multiple descriptions' do
          let(:descr) { ["A free text description.", "Another one."] }
          before { work.description = descr }

          it 'generates the correct xml' do
            expect(subject.css('descriptions').count).to eq 1
            expect(subject.css('description').count).to eq 2
            expect(subject.css('description').map { |tag| tag.attributes['descriptionType'].value }).to all(eq("Abstract"))
            expect(subject.css('description').map(&:inner_text)).to match(["A free text description.", "Another one."])
          end
        end
      end
    end

    describe 'subjects' do
      context 'when work has subjects and/or keywords' do
        let(:uri) { subject.css('subject')[0] }
        let(:string) { subject.css('subject')[1] }
        let(:subjects) { [Hyrax::ControlledVocabularies::Subject.new("https://id.worldcat.org/fast/1214700"),
                             "Literal subject"] }
        let(:keywords) { ["Special keyword"] }

        before do
          work.subject = subjects
          work.keyword = keywords
        end

        it 'generates the correct xml for FAST uris' do
          expect(subject.css('subject').count).to eq 3
          expect(uri.inner_text).to eq "British Columbia--Victoria"
          expect(uri.attributes['subjectScheme'].value).to eq "FAST"
          expect(uri.attributes['schemeURI'].value).to eq "https://id.worldcat.org/fast"
        end

        it 'generates the correct xml for textual values' do
          expect(subject.css('subject').count).to eq 3
          expect(string.inner_text).to eq "Literal subject"
          expect(subject.css('subject')[2].inner_text).to eq "Special keyword"
        end
      end

      context 'when subject is blank' do
        it 'does not insert anything into subjects' do
          expect(subject.css('subjects').count).to be 0
          expect(subject.css('subject').count).to be 0
        end
      end
    end

    describe 'geo locations' do

      context 'with one or more geo locations' do
        context 'when geo location is a uri' do
          let(:geolocation) { [Hyrax::ControlledVocabularies::GeographicCoverage.new("https://id.worldcat.org/fast/1214700")] }
          before { work.geographic_coverage = geolocation }

          it 'inserts the label into geoLocation' do
            expect(subject.css('geoLocations').count).to eq 1
            expect(subject.css('geoLocation').count).to eq 1
            expect(subject.at_css('geoLocationPlace').inner_text).to eq "British Columbia--Victoria"
          end

          it 'inserts coordinates from FAST' do
            expect(subject.css('geoLocationPoint').count).to eq 1
            expect(subject.css('pointLongitude').text).to eq "-123.36916"
            expect(subject.css('pointLatitude').text).to eq "48.43306"
          end
        end

        context 'when geo location is a single textual value' do
          let(:geolocation) { ["British Columbia--Pitt River"] }
          before { work.geographic_coverage = geolocation }

          it 'inserts the value into geoLocation' do
            expect(subject.css('geoLocations').count).to eq 1
            expect(subject.css('geoLocation').count).to eq 1
            expect(subject.at_css('geoLocationPlace').inner_text).to eq "British Columbia--Pitt River"
          end

          context 'and there is only one matching coordinate' do
            let(:coordinates) { ["27.792, -127.0055"] }
            before { work.coordinates = coordinates }

            it 'inserts the coordinate into the XML' do
              expect(subject.css('geoLocationPoint').count).to eq 1
              expect(subject.css('pointLongitude').text).to eq "-127.0055"
              expect(subject.css('pointLatitude').text).to eq "27.792"
            end
          end

          context 'with multiple coordinates' do
            let(:coordinates) { ["27.797, -127.0055", "88.8888, 88.8888"] }
            before { work.coordinates = coordinates }

            it 'omits coordinates from textual values' do
              expect(subject.css('geoLocationPoint').count).to eq 0
            end
          end
        end
      end

      context 'when geo location is blank' do
        it 'does not insert anything into geo location' do
          expect(subject.css('geoLocations').count).to be 0
          expect(subject.css('geoLocation').count).to be 0
        end
      end
    end

    describe 'dates' do
      context 'when work has no date created' do
        it "leaves the date field blank" do
          expect(subject.css('dates').count).to eq 0
        end
      end

      context 'when date created is "unknown"' do
        before { work.date_created = ["unknown"] }
        it "leaves the date field blank" do
          expect(subject.css('dates').count).to eq 0
        end
      end

      context 'when date created is "no date"' do
        before { work.date_created = ["no date"] }
        it "leaves the date field blank" do
          expect(subject.css('dates').count).to eq 0
        end
      end

      context 'when date created is a single date' do
        before { work.date_created = ["1982-06-25"] }
        it "inserts the date in ISO format" do
          expect(subject.css('dates').count).to eq 1
          expect(subject.at_css('date').inner_text).to eq "1982-06-25"
          expect(subject.at_css('date').attributes['dateType'].value).to eq "Created"
        end
      end

      context 'when date created is an interval or a season' do
        context 'when date is an interval' do
          before { work.date_created = ["1982/1995"] }
          it "inserts the date created in ISO format" do
            expect(subject.css('dates').count).to eq 1
            expect(subject.at_css('date').inner_text).to eq "1982/1995"
            expect(subject.at_css('date').attributes['dateType'].value).to eq "Created"
          end
        end

        context 'when date is a decade' do
          before { work.date_created = ["191X"] }
          it "inserts the date created into the xml as an interval" do
            expect(subject.css('dates').count).to eq 1
            expect(subject.at_css('date').inner_text).to eq "1910/1919"
            expect(subject.at_css('date').attributes['dateType'].value).to eq "Created"
          end
        end

        context 'when date is a century' do
          before { work.date_created = ["18XX"] }
          it "inserts the date created into the xml as an interval" do
            expect(subject.css('dates').count).to eq 1
            expect(subject.at_css('date').inner_text).to eq "1800/1899"
            expect(subject.at_css('date').attributes['dateType'].value).to eq "Created"
          end
        end

        context 'when date is a season' do
          before { work.date_created = ["1912-24"] }
          it "inserts the date created into the xml as an interval" do
            expect(subject.css('dates').count).to eq 1
            expect(subject.at_css('date').inner_text).to eq "1912-12-01/1913-02-28"
            expect(subject.at_css('date').attributes['dateType'].value).to eq "Created"
          end
        end

        context 'when date is an open-ended interval' do
          before { work.date_created = ["../1897","1897/.."] }
          it "inserts the date created into the xml as an interval" do
            expect(subject.css('date')[0].inner_text).to eq "/1897"
            expect(subject.css('date')[1].inner_text).to eq "1897/"
          end
        end
      end
    end
  end

  describe 'optional fields' do
    describe "rights list" do
      before { work.rights_statement = ["https://creativecommons.org/publicdomain/mark/1.0/"] }
      it "inserts the rights statement URI into the xml" do
        expect(subject.css('rightsList').count).to eq 1
        expect(subject.css('rights').count).to eq 1
        expect(subject.at_css('rights').inner_text).to eq "Public Domain Mark 1.0"
        expect(subject.at_css('rights').attributes['rightsURI'].value).to eq "https://creativecommons.org/publicdomain/mark/1.0/"
      end
    end

    describe "alternate identifiers" do
      before { work.id = "foo" }
      it "inserts the Hyrax work id into the xml" do
        expect(subject.css('alternateIdentifiers').count).to eq 1
        expect(subject.css('alternateIdentifier').count).to eq 1
        expect(subject.at_css('alternateIdentifier').inner_text).to eq "foo"
        expect(subject.at_css('alternateIdentifier').attributes['alternateIdentifierType'].value).to eq "A local Hyrax object identifier"
      end
    end

    describe "formats" do
      let(:file_set1) { FileSet.new }
      let(:file_set2) { FileSet.new }
      let(:file_set3) { FileSet.new }

      before do
        allow(file_set1).to receive(:mime_type).and_return("video/mp4")
        allow(file_set2).to receive(:mime_type).and_return("application/pdf")
        allow(file_set3).to receive(:mime_type).and_return("image/jpeg")
        allow(work).to receive(:file_sets).and_return([file_set1, file_set2, file_set3])
      end

      it "inserts file mime types into the xml" do
        expect(subject.css('formats').count).to eq 1
        expect(subject.css('format').count).to eq 3
        expect(subject.css('format').map(&:inner_text)).to eq ["video/mp4","application/pdf","image/jpeg"]
      end
    end

    describe "language" do
      before { work.language = ["eng", "chi"] }
      it "uses only the first language (because DataCite only accepts 1)" do
        expect(subject.css('language').count).to eq 1
        expect(subject.at_css('language').inner_text).to eq "eng"
      end
    end
  end
end
RSpec.describe GeonamesHierarchyService do

  subject { described_class.call(geonames_uri) }

  context 'when place is in format name, admin region, country' do

    let(:geonames_uri) { "https://sws.geonames.org/6174041/" }

    it 'returns an array in format name, admin region, country, continent' do
      expect(subject).to eq ["Victoria", "Vancouver Island", "British Columbia", "Canada", "North America"]
    end

    context 'when place is on Vancouver Island' do
      it 'returns an array that includes "Vancouver Island"' do
        expect(subject).to include "Vancouver Island"
      end
    end

    context 'when place is not on Vancouver Island' do

      let(:geonames_uri) { "https://sws.geonames.org/2964574/" }

      it 'returns an array without "Vancouver Island"' do
        expect(subject).not_to include "Vancouver Island"
      end
    end


  end

  context 'when place is a province' do

    let(:geonames_uri) { "https://sws.geonames.org/5909050/" }

    it 'returns an array without an admin region, empty strings, or duplicate strings' do
      expect(subject).to eq ["British Columbia", "Canada", "North America"]
    end
  end

  context 'when place is a country' do

    let(:geonames_uri) { "https://sws.geonames.org/1814991/" }

    it 'returns an array without an admin region, empty strings, or duplicate strings' do
      expect(subject).to eq ["China", "Asia"]
    end
  end
end
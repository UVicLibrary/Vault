RSpec.describe FastUpdate::XlsxParser, type: :model do


  describe '#parse_data' do

    subject { FastUpdate::XlsxParser.new("spec/fixtures/FASTChangeReport2022-10-28.xlsx").parse_data }

    it "returns an array of XlsxChange objects" do
      expect(subject).to be_a Array
      expect(subject).to all be_a FastUpdate::XlsxChange
    end

    it "creates attributes for new headings" do
      expected_attributes = { type: "New Heading", uri: "http://id.worldcat.org/fast/2013910",
                              label: "Ópera de Bilbao", fast_id: "fst02013910", suggestions: nil }
      expect(subject.first.attributes).to eq(expected_attributes)
    end

    it "creates attributes for modified headings" do
      expected_attributes = { type: "Modified Heading", uri: "http://id.worldcat.org/fast/2012640",
                              label: "Fantasia Fair", fast_id: "fst02012640", suggestions: nil }
      expect(subject.second.attributes).to eq(expected_attributes)
    end

    it "creates attributes for obsolete headings" do
      expected_attributes = { type: "Obsolete", uri: "http://id.worldcat.org/fast/2048330",
                              label: "Cundinamarca (Colombia : Department). Junta General de Beneficencia",
                              fast_id: "fst02048330", suggestions: nil }
      expect(subject[2].attributes).to eq(expected_attributes)
    end

    it "creates attributes, including suggestions, for deprecated headings" do
      expected_attributes = { type: "Deprecated", uri: "http://id.worldcat.org/fast/1209002",
                              label: "Japan--Matsunaga-shi", fast_id: "fst01209002",
                              suggestions: [{ uri: "http://id.worldcat.org/fast/1208999", label: "Japan Fukuyama-shi" }] }
      expect(subject[3].attributes).to eq(expected_attributes)
    end

    it "creates attributes, including suggestions, for split headings" do
      expected_attributes = { type: "Split", uri: "http://id.worldcat.org/fast/921949",
                              label: "Fatigue--Testing", fast_id: "fst00921949",
                              suggestions: [{ uri: "http://id.worldcat.org/fast/921951", label: "Fatigue testing machines" },
                                            { uri: "http://id.worldcat.org/fast/1011834", label: "Materials--Fatigue" }] }
      expect(subject[4].attributes).to eq(expected_attributes)
    end

    it "ignores 'Other Changes' type" do
      expect(subject.find { |change| change.type == "Other Change" }).to be_nil
    end

    context "if change type is not recognized" do
      subject { FastUpdate::XlsxParser.new("spec/fixtures/unknown_change_type.xlsx").parse_data }

      it "raises an error" do
        expect { subject }.to raise_error(FastUpdate::XlsxParser::UnknownChangeTypeError,/Change type not recognized: Rando Change/)
      end
    end

  end
end
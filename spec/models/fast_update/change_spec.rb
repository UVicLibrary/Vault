# This uses the shoulda-matchers gem, which is bundled with Hyrax
RSpec.describe FastUpdate::Change, type: :model do

  describe "validations" do

    subject { described_class.new(
        old_uri: "http://id.worldcat.org/fast/1092912",
        action: "replace",
        new_uris: ["http://id.worldcat.org/fast/549011"],
        new_labels: ["Tiffany and Company"],
        collection_id: "all"
    ) }

    it { is_expected.to validate_presence_of :old_uri }
    it { is_expected.to validate_presence_of :action }
    it { is_expected.to validate_inclusion_of(:action).in_array(["replace", "delete"]) }
    it { is_expected.to validate_presence_of :collection_id }

    describe "validate format of old URI" do
      it { is_expected.to allow_value(subject.old_uri).for(:old_uri) }
      it { is_expected.not_to allow_value("function maliciousCode(){ deleteAllTheThings }").for(:old_uri) }
    end

    context "when the action is 'replace'" do
      before { allow(subject).to receive(:action).and_return("replace") }
      it { is_expected.to validate_presence_of(:new_uris).with_message("must be selected to replace the old one") }
    end

    context "when the action is 'delete'" do
      before { allow(subject).to receive(:action).and_return("delete") }
      it { is_expected.not_to validate_presence_of(:new_uris) }
    end

  end
end

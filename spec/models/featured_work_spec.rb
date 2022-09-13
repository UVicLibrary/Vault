RSpec.describe FeaturedWork, type: :model do
  let(:feature) { described_class.create(work_id: "99") }

  it "has a file" do
    expect(feature.work_id).to eq "99"
  end

  it "does not allow nine features" do
    8.times do |n|
      expect(described_class.create(work_id: n.to_s)).not_to be_new_record
    end
    described_class.create(work_id: "9").tap do |sixth|
      expect(sixth).to be_new_record
      expect(sixth.errors.full_messages).to eq ["Limited to 8 featured works."]
    end
    expect(described_class.count).to eq 8
  end

  describe "can_create_another?" do
    subject { described_class }

    context "when none exist" do
      describe '#can_create_another?' do
        subject { super().can_create_another? }

        it { is_expected.to be true }
      end
    end
    context "when six exist" do
      before do
        8.times do |n|
          described_class.create(work_id: n.to_s)
        end
      end

      describe '#can_create_another?' do
        subject { super().can_create_another? }

        it { is_expected.to be false }
      end
    end
  end

  describe "#order" do
    subject { described_class.new(order: 8) }

    describe '#order' do
      subject { super().order }

      it { is_expected.to eq 8 }
    end
  end
end

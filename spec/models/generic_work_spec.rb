RSpec.describe GenericWork do
  describe 'indexer' do
    subject { described_class.indexer }

    it { is_expected.to eq GenericWorkIndexer }
  end
end

# frozen_string_literal: true
RSpec.describe VaultDispatcher do
  subject(:dispatcher) { described_class.new(registrar: fake_registrar.new) }
  let(:identifier)     { '10.11111/moomin' }
  let(:object)         { build(:generic_work) }

  let(:fake_registrar) do
    Class.new do
      def initialize(*); end

      def register!(*)
        Struct.new(:identifier).new('10.11111/moomin')
      end
    end
  end

  it 'uses the Vault registrar for DataCite' do
    expect(described_class.for(:datacite).registrar).to be_a VaultDataCiteRegistrar
  end

  shared_examples 'performs identifier assignment' do |method|
    it 'returns the same object' do
      expect(dispatcher.public_send(method, object: object)).to eql object
    end

    it 'assigns to the doi attribute by default' do
      dispatcher.public_send(method, object: object)
      expect(object.doi).to contain_exactly(identifier)
    end
  end

  describe '#assign_for' do
    include_examples 'performs identifier assignment', :assign_for
  end

  describe '#assign_for!' do
    include_examples 'performs identifier assignment', :assign_for!

    it 'saves the object' do
      expect { dispatcher.assign_for!(object: object) }
          .to change { object.new_record? }
                  .from(true)
                  .to(false)
    end
  end
end
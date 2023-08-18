RSpec.describe AssignWorkDOIJob, perform_enqueued: [AssignWorkDOIJob] do
  let(:work) { GenericWork.new(title: ["A work"], provider: ["http://id.worldcat.org/fast/549011"], id: "foo") }
  let(:work_with_doi) { GenericWork.new(doi: ["99.9999/9999"]) }
  let(:dispatcher) { VaultDispatcher.new(registrar: VaultDataCiteRegistrar.new) }

  before do
    allow(VaultDispatcher).to receive(:for).with(:datacite).and_return(dispatcher)
    allow(dispatcher).to receive(:assign_for!)
  end

  context 'when work already has a DOI' do
    it 'exits the job' do
      described_class.perform_now(work_with_doi)
      expect(dispatcher).not_to have_received(:assign_for!)
    end
  end

  describe '#perform' do

    before { described_class.perform_now(work) }

    it 'sets the work DOI status (when public) to findable' do
      expect(work.doi_status_when_public).to eq "findable"
    end

    it 'converts uris to Hyrax::ControlledVocabularies::FieldName' do
      expect(work.provider.first).to be_instance_of(Hyrax::ControlledVocabularies::Provider)
      expect(work.provider.first.id).to eq "http://id.worldcat.org/fast/549011"
    end

    it 'tries to assign a DOI' do
      expect(dispatcher).to have_received(:assign_for!)
    end
  end

  describe 'error handling' do

    context 'when error might be a connection error' do

      before do
        allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
        allow(described_class).to receive(:perform_later).and_call_original
        allow(dispatcher).to receive(:assign_for!).and_raise Net::ReadTimeout.new
      end

      it 'raises the exception as normal' do
         expect { described_class.perform_now(work) }.to raise_error(Net::ReadTimeout)
      end
    end

    context 'when error is possibly metadata-related' do

      before do
        allow(dispatcher).to receive(:assign_for!).and_raise Hyrax::DOI::DataCiteClient::Error.new
        allow(NotificationMailer).to receive(:with).and_call_original
        allow(NotificationMailer).to receive(:failures).and_call_original
        # Set this in config/settings.yml. This test needs the :fixity_email key in Settings in order to pass.
        allow(Settings).to receive(:fixity_email).and_return("user@example.com")
      end

      it 'calls the notification mailer' do
        expect(NotificationMailer).to receive(:with).with(user_email: "user@example.com", failures: ["foo"], job_class: AssignWorkDOIJob)
        expect { described_class.perform_now(work) }.not_to raise_error # since it is rescued
      end
    end
  end

end
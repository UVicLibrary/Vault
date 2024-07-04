# frozen_string_literal: true

RSpec.describe JobFailedMailer, type: :mailer do

  let(:mail) { described_class.mail_failures(failures: ["foo"], job_class: ExportFileJob) }
  old_env = ENV['JOB_FAILED_USER_EMAIL']

  before { ENV['JOB_FAILED_USER_EMAIL'] = "admin@example.com" }

  describe '#mail_failures' do
    it 'emails the specified user with the failed ids' do
      expect(mail.to).to eq ["admin@example.com"]
      expect(mail.subject).to eq "ExportFileJob Failed"
      expect(mail.body.encoded).to include "foo"
    end
  end

  describe '#fixity_failures' do
    let(:mail) { described_class.fixity_failures(file_sets: [file_set]) }
    let(:account) { double(Account) }
    let(:file_set) { FileSet.new(id: 'foo', title: ['Title']) }
    let(:file) { double }
    let(:checksum) { double }

    before do
      allow(Apartment::Tenant).to receive(:current).and_return("vault.library.uvic.ca")
      allow(Account).to receive(:find_by).with(any_args).and_return(account)
      allow(account).to receive(:cname).and_return("vault.library.uvic.ca")

      allow(file_set).to receive(:files).and_return([file])
      allow(file_set).to receive(:original_checksum).and_return(['aaa'])
      allow(file_set).to receive(:current_checksum).and_return('bbb')
      allow(file).to receive(:checksum).and_return(checksum)
      allow(checksum).to receive(:value).and_return('ccc')
    end

    it 'emails the specified user with links and checksums' do
      expect(mail.to).to eq ["admin@example.com"]
      expect(mail.subject).to eq "Fixity Check - Possible Corrupted Files"
      expect(mail.body.encoded).to include("https://vault.library.uvic.ca/concern/file_sets/foo")
      expect(mail.body.encoded).to include("https://vault.library.uvic.ca/downloads/foo")
      expect(mail.body.encoded).to include('aaa').and include('bbb').and include('ccc')
    end
  end

  after { ENV['JOB_FAILED_USER_EMAIL'] = old_env }
end
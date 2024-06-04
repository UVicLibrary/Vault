# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::ContactMailer, type: :mailer do
  let(:account) { FactoryBot.create(:account) }
  let(:contact_form) do
    Hyrax::ContactForm.new(
        email: 'test@example.com',
        category: 'Test',
        subject: 'Test',
        name: 'Test Tester',
        message: 'This is a test'
    )
  end
  let(:mail) { described_class.contact(contact_form) }

  describe "reset_password_instructions" do

    it "renders the body" do
      allow(Site).to receive(:account).and_return(account)
      expect(mail.body.encoded).to match(/Test Tester/)
    end
  end

  describe "submitting the form from the Contact page" do
    let(:headers) do
      {   subject: "Contact form: test subject",
          to: "test@example.com",
          from: "bogus@example.com"   }
    end

    before do
      allow(Site).to receive(:account).and_return(account)
      allow(contact_form).to receive(:headers).and_return(headers)
    end

    it "changes the :from header to a generic address" do
      expect(mail.from).not_to eq "no-reply@uvic.ca"
    end

    it "sets the :reply_to header to the original :from header" do
      expect(mail.reply_to).to eq ["bogus@example.com"]
    end
  end
end
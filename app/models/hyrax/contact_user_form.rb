module Hyrax
  class ContactUserForm < ContactForm

    # Declare the e-mail headers. It accepts anything the mail method
    # in ActionMailer accepts.
    def headers
      {
          subject: "#{subject} - #{HykuMailer.new.default_url_options[:host]}",
          to: Hyrax.config.contact_email,
          from: Rails.application.config.action_mailer.default_options[:from],
          reply_to: email
      }
    end

  end
end
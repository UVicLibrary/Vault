module Hyrax
  class ContactUserForm < ContactForm

    # Declare the e-mail headers. It accepts anything the mail method
    # in ActionMailer accepts.
    def headers
      {
          # "subject" and "to" are set later in mailers/contact_mailer
          from: email
      }
    end

  end
end
# frozen_string_literal: true

module Hyrax
  # Mailer for contacting the administrator. The "to" email address is set
  # via account.contact_email. To change the address, call
  # account.contact_mail = adminstrator@example.com
  class ContactMailer < HykuMailer
    def contact(contact_form)
      @contact_form = contact_form
      # Check for spam
      return if @contact_form.spam?
      headers = @contact_form.headers.dup
      headers[:subject] += " [#{host_for_tenant}]"
      mail(headers)
    end
  end
end
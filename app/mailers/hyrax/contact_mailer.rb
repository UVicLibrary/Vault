# frozen_string_literal: true

# OVERRIDE Hyrax 3.4.2 and Hyku v.2
# Use :reply_to header instead of :from to avoid
# errors hitting mail server

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
      headers[:reply_to] = headers.delete(:from)
      Rails.logger.debug("headers = #{headers.inspect}")
      mail(headers)
    end

  end
end

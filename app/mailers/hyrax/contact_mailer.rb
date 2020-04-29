module Hyrax
  # Mailer for contacting the administrator
  class ContactMailer < HykuMailer
    def contact(contact_form, *user_id)
      @contact_form = contact_form
      # See controllers/hyrax/contact_form_controller#create
      @user = ::User.find(user_id).first
      # Check for spam
      return if @contact_form.spam?
      headers = @contact_form.headers.dup
      headers[:subject] = "#{headers[:subject]} #{default_url_options[:host]}"
      if @user.present?
        headers["to"] << @user.email
      end
      mail(headers)
    end
  end
end

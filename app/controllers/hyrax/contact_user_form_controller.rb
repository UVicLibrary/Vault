module Hyrax
  class ContactUserFormController < ContactFormController
    before_action :build_contact_form
    layout 'homepage'

    def new
      @contact_form = ContactUserForm.new
    end

    def create
      # not spam and a valid form
      if @contact_form.valid?
        ContactMailer.contact(@contact_form, params[:user_id]).deliver_now
        after_deliver
        flash[:notice] = 'Thank you for your message!'
        redirect_to user_path(::User.find(params[:user_id]))
      else
        flash.now[:error] = 'Sorry, this message was not sent successfully. '
        flash.now[:error] << @contact_form.errors.full_messages.map(&:to_s).join(", ")
      end
    rescue RuntimeError => exception
      handle_create_exception(exception)
    end


    private

    def build_contact_form
      @contact_form = Hyrax::ContactUserForm.new(contact_form_params)
    end

    def contact_form_params
      return {} unless params.key?(:contact_user_form)
      params.permit(:user_id)
      params.require(:contact_user_form).permit(:contact_method, :category, :name, :email, :subject, :message)
    end
  end
end
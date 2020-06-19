module Hyrax
  class ToggleVisibilityJob < Hyrax::ApplicationJob
  # Params passed in from views/hyrax/dashboard/collections/_show_actions.html.erb when button is clicked
  # user_email = the email address of user who started the job
  # visibility = "public" or "private"
  # host = "https://vault.library.uvic.ca"
    def perform(collection_id, user_email, visibility, host) # Need user email for notification when job is finished
      collection = Collection.find(collection_id)
      works = GenericWork.where(member_of_collection_ids_ssim: collection_id)
      if visibility == "public"
        works.each do |work|
          work.members.each do |member|
            make_public(member)
          end
        make_public(work)
        end
        make_public(collection)
      else # == "private"
        works.each do |work|
          work.members.each do |member|
            make_private(member)
          end
        make_private(work)
        end
        make_private(collection)
      end
      # Send an email when done
      ::NotificationMailer.with(account_host: host, user_email: user_email, id: collection_id, visibility: visibility).email_notification.deliver
    end

    private

    def make_public(object)
      object.visibility = "open"
      object.save
    end

    def make_private(object)
      object.visibility = "restricted"
      object.save
    end

  end

end

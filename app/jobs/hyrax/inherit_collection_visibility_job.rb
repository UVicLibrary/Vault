module Hyrax
  class InheritCollectionVisibilityJob < Hyrax::ApplicationJob
  # Params passed in from views/hyrax/dashboard/collections/_show_actions.html.erb
  # when user clicks a button
  # user_email = the email address of user who started the job
  # visibility = "open" (i.e. public), "authenticated" (i.e. UVic-only),
  # "restricted" (i.e. private)
  # host = "https://vault.library.uvic.ca"
    def perform(collection_id, user_email, visibility, host) # Need user email for notification when job is finished
      collection = Collection.find(collection_id)
      works = GenericWork.where(member_of_collection_ids_ssim: collection_id)
      works.each do |work|
        work.members.each do |member|
          change_visibility(member, visibility)
        end
        change_visibility(work, visibility)
      end
      change_visibility(collection, visibility)
      # Send an email when done
      # ::VisibilityPermissionsMailer.with(account_host: host, user_email: user_email, id: collection_id, visibility: visibility).inherit_visibility.deliver
    end

    private

    def change_visibility(object, visibility)
      object.visibility = visibility
      object.save!
    end

  end

end

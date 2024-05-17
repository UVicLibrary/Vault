module Hyrax
  class InheritCollectionVisibilityJob < Hyrax::ApplicationJob
  # Params passed in from views/hyrax/dashboard/collections/_show_actions.html.erb
  # when user clicks a button
  # @param [String] - collection_id
  # @param [String] - the email address of user who started the job and whom is notified
  #                   when the job is complete
  # @param[String] - visibility can be "open" (public), "authenticated" (UVic-only), or "restricted" (private)
  # @param[String] - host: usually "vault.library.uvic.ca"
    def perform(collection_id, user_email, visibility, host)
      # In Valkyrie, this query may become:
      # Hyrax.query_service.custom_queries.find_child_works(resource: collection)
      works = GenericWork.where(member_of_collection_ids_ssim: collection_id).select { |w| w.visibility != visibility }
      works.each do |work|
        work.members.each do |member|
          change_visibility(member, visibility)
          member.save!
        end
        change_visibility(work, visibility)
        update_doi_status(work)
        work.save!
        ConvertWorkDownloadPermissionsJob.perform_later(work)
        # Assign a findable DOI if the work is public or UVic-only.
        # Otherwise, change the DOI (if any) to registered state.
        Hyrax::DOI::RegisterDOIJob.perform_later(work, registrar: work.doi_registrar.presence, registrar_opts: work.doi_registrar_opts)
      end
      # In Valkyrie, this query may become:
      # collection = Hyrax.query_service.find_by(id: collection_id)
      collection = Hyrax.config.collection_class.find(collection_id)
      change_visibility(collection, visibility)
      collection.save!
      # Send an email when done
      ::VisibilityPermissionsMailer.with(account_host: host, user_email: user_email, id: collection_id, visibility: visibility).inherit_visibility.deliver
    end

    private

    def change_visibility(object, visibility)
      object.visibility = visibility
    end

    # Set its doi status to "findable." If a work is now public/UVic-only,
    # this will cause Hyrax::DOI::RegisterDOIJob to assign a new DOI.
    # If a work is now private, this will change the DOI status to "registered"
    def update_doi_status(work)
      work.doi_status_when_public = "findable"
    end
  end

end

class BatchAssignWorkDOIsJob < ApplicationJob

  # @param [Array <GenericWork>]
  # To get all works in a collection, use Collection.find(id).member_works
  def perform(works)
    works do |work|
      next if work.doi.present?
      AssignWorkDOIJob.perform_later(work)
    end
  end

end
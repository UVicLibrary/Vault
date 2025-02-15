class ReindexObjectJob < ActiveJob::Base

  def perform(id)
    ActiveFedora::Base.find(id).save!
  end

end
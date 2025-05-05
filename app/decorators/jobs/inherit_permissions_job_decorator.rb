InheritPermissionsJob.class_eval do

  # Intermittent error where job that fails on 1st try (but later
  # succeeds) causes work to appear private, even when it has
  # been set to public. Resaving the work solves this issue.
  rescue_from(ActiveFedora::ModelMismatch) do |_exception|
    work = arguments[0]
    case work
    when ActiveFedora::Base
      work.save! && work.update_index
    else
      Hyrax.persister.save(resource: work)
    end
    retry_job
  end

  after_perform do |job|
    work = job.arguments.first
    case work
    when ActiveFedora::Base
      work.update_index
    end
  end

end
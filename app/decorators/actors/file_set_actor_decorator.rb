# frozen_string_literal: true
#
# OVERRIDE Hyrax 3.5
module FileSetActorDecorator

  # Overridden to NOT set the file set's creator to the depositor.
  # Since many of our objects are historical, the creator is really
  # the work's creator (if known)
  def create_metadata(file_set_params = {})
    file_set.depositor = depositor_id(user)
    now = Hyrax::TimeService.time_in_utc
    file_set.date_uploaded = now
    file_set.date_modified = now
    if assign_visibility?(file_set_params)
      env = Hyrax::Actors::Environment.new(file_set, ability, file_set_params)
      Hyrax::CurationConcern.file_set_create_actor.create(env)
    end
    yield(file_set) if block_given?
  end

  def update_metadata(attributes)
    env = Hyrax::Actors::Environment.new(file_set, ability, attributes)

    # When adding string values into controlled properties, Hyrax will assume
    # they are URIs unless we clean the values
    env.curation_concern.attributes = clean_controlled_properties(env, env.attributes)

    Hyrax::CurationConcern.file_set_update_actor.update(env)
  end

  # Adds a FileSet to the work using ore:Aggregations.
  def attach_to_af_work(work, file_set_params)
    super
    # Only set the file set's creator to the work creator if there isn't one provided
    if file_set.creator.blank? or file_set.creator == work.depositor
      file_set.creator = work.creator unless work.creator.blank?
    end
    file_set.save
    # file_set.update_index
  end

  # If the first ordered file set is deleted, set the
  # parent's thumbnail and representative to the next
  # file set in order
  def unlink_from_work
    work = parent_for(file_set: file_set)
    return unless work && (work.thumbnail_id == file_set.id || work.representative_id == file_set.id || work.rendering_ids.include?(file_set.id))
    # Use the (new) first file set
    if work.thumbnail_id == file_set.id
      work.thumbnail_id = (work.ordered_member_ids - [file_set.id]).first
    end
    if work.representative_id == file_set.id
      work.representative_id = (work.ordered_member_ids - [file_set.id]).first
    end
    work.rendering_ids -= [file_set.id]
    work.save!
  end

  def clean_controlled_properties(env, attributes)
    qa_attributes = {}
    env.curation_concern.controlled_properties.each do |field_symbol|
      field = field_symbol.to_s
      # Do not include deleted attributes
      next unless attributes.keys.include?(field+'_attributes')
      filtered_attributes = attributes[field+'_attributes'].select  { |_,v| v['_destroy'].blank? }
      qa_attributes[field] = filtered_attributes.map { |attr| attr[1]['id'] }
      attributes.delete(field)
      attributes.delete(field+'_attributes')
    end
    env.curation_concern.attributes = qa_attributes
    env.curation_concern.to_controlled_vocab
    # save(env)
    attributes
  end

end
Hyrax::Actors::FileSetActor.prepend(FileSetActorDecorator)
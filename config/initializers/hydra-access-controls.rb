Hydra::AccessControls::Permissions.module_eval do
  # Problem in production with permissions_attributes being duplicated in
  # the collection and consequently in the Solr doc. Added .uniq on line 15
  # to prevent duplicates.
  def permissions_attributes=(attributes_collection)
    if attributes_collection.is_a? Hash
      keys = attributes_collection.keys
      attributes_collection = if keys.include?('id') || keys.include?(:id)
                                Array(attributes_collection)
                              else
                                attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes }
                              end
    end

    attributes_collection = attributes_collection.uniq.map(&:with_indifferent_access)
    attributes_collection.each do |prop|
      existing = case prop[:type]
                 when 'group'
                   search_by_type(:group)
                 when 'person'
                   search_by_type(:person)
                 end

      next if existing.blank?
      selected = existing.find { |perm| perm.agent_name == prop[:name] }
      prop['id'] = selected.id if selected
    end

    clean_collection = remove_bad_deletes(attributes_collection)

    self.permissions_attributes_without_uniqueness = clean_collection
  end
end
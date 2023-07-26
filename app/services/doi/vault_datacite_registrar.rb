class VaultDataCiteRegistrar < Hyrax::DOI::DataCiteRegistrar

  # Do the heavy lifting of submitting the metadata, registering the url, and ensuring the correct status
  def submit_to_datacite(work, doi)
    # 1. Add metadata to the DOI (or update it)
    # TODO: check that required metadata is present if current DOI record is registered or findable OR handle error?
    client.put_metadata(doi, work_to_datacite_xml(work, doi))

    # 2. Register a url with the DOI if it should be registered or findable
    client.register_url(doi, work_url(work)) if work.doi_status_when_public.in?(['registered', 'findable'])

    # 3. Always call delete metadata unless findable and public
    # Do this because it has no real effect on the metadata and
    # the put_metadata or register_url above may have made it findable.
    client.delete_metadata(doi) unless work.doi_status_when_public == 'findable' && public?(work)
  end

  # @param [GenericWork]
  # @param [String] - the existing or draft DOI for the given work
  def work_to_datacite_xml(work, doi)
    Bolognese::Metadata.new(input: work.attributes.merge({ create_date: work.create_date, mime_types: mime_types(work) }).to_json, from: 'generic_work', doi: doi).datacite
  end

  # @return [Array] - the mime types of file sets in the work
  def mime_types(work)
    work.file_sets.map(&:mime_type).uniq
  end

end
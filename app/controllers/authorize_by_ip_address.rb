module AuthorizeByIpAddress

  # Allow public users who are on campus (detected using IP address) to access UVic-only works.
  # For all other users, run the usual authorization checks.
  # @param [SolrDocument]
  def authorize_by_ip(curation_concern)
    if authorized_by_ip?(curation_concern)
      current_ability.can(:read, curation_concern)
    else
      authorize! :show, curation_concern
    end
  end

  def authorized_by_ip?(doc_or_presenter)
    visibility(doc_or_presenter) == "authenticated" && ip_on_campus?
  end

  def visibility(doc_or_presenter)
    doc_or_presenter.respond_to?(:visibility) ? doc_or_presenter.visibility : doc_or_presenter['visibility_ssi']
  end

  def ip_on_campus?
    user_ip = IPAddr.new(request.remote_ip)
    allowed_ips = Settings.allowed_ip_ranges.map { |ip| IPAddr.new(ip) }
    allowed_ips.any? { |ip_range| ip_range.include?(user_ip) }
  end
end
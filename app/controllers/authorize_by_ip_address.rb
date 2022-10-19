module AuthorizeByIpAddress
  # Allow public users who are on campus (detected using IP address) to access UVic-only works
  def authorize_by_ip
    curation_concern = curation_concern_from_search_results
    unless curation_concern.visibility == "authenticated" && ip_on_campus?
      authorize! :show, curation_concern
    end
  end

  def ip_on_campus?
    user_ip = IPAddr.new(request.remote_ip)
    allowed_ips = Settings.allowed_ip_ranges.map { |ip| IPAddr.new(ip) }
    allowed_ips.any? { |ip_range| ip_range.include?(user_ip) }
  end
end
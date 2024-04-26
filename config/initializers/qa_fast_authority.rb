# OVERRIDE Questioning Authority (qa) gem v. 5.11.0
#
# This is the endpoint used in autocomplete boxes on the work edit page
# for all fields that use OCLC FAST (/authorities/search/assign_fast/all).
# See the qa documentation for more info:
# https://github.com/samvera/questioning_authority/wiki/Connecting-to-OCLC-FAST
#
# By default, this returns the fast ID (e.g. "fst01910008"), which is
# what the fast API is meant to return. However, this causes problems
# when it comes to indexing the URI & label (see Hyrax::DeepIndexingService),
# since the RDF gem can only fetch information using a URI
# (e.g. "https://id.worldcat.org/fast/1910008" ) and not the fast ID.
# To ensure the metadata indexes properly, we're changing the result to
# return the full URI instead of only the ID.
Rails.application.config.to_prepare do
  Qa::Authorities::AssignFast::GenericAuthority.class_eval do

    def parse_authority_response(raw_response)
      raw_response['response']['docs'].map do |doc|
        index = Qa::Authorities::AssignFast.index_for_authority(subauthority)
        term = doc[index].first
        term += ' USE ' + doc['auth'] if doc['type'] == 'alt'
        { id: id_to_uri(doc['idroot']), label: term, value: doc['auth'] }
      end
    end

    def id_to_uri(id)
      "http://id.worldcat.org/fast/#{id.gsub('fst','').gsub(/^0+/, '')}"
    end
  end
end
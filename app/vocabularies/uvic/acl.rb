module Uvic
  class ACL < RDF::StrictVocabulary('http://library.uvic.ca/ns/uvic/auth/acl#')
    property :Download # extends http://www.w3.org/ns/auth/acl#Access
  end
end
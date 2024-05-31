# OVERRIDE class from Hyrax v. 3.4.2
module PcdmMemberPresenterFactoryDecorator

  # Add brackets around the id query (otherwise query results
  # are always blank)
  def query_docs(generic_type: nil, ids: object.member_ids)
    query = "({!terms f=id}#{ids.join(',')})"
    query += "{!term f=generic_type_si}#{generic_type}" if generic_type

    Hyrax::SolrService
        .post(q: query, rows: 10_000)
        .fetch('response')
        .fetch('docs')
  end

end
Hyrax::PcdmMemberPresenterFactory.prepend(PcdmMemberPresenterFactoryDecorator)
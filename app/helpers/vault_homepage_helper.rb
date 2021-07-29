module VaultHomepageHelper

  def render_card_collection_links(solr_doc)
    collection_list = Hyrax::CollectionMemberService.run(solr_doc, controller.current_ability)
    return if collection_list.empty?
    links = collection_list.map { |collection| link_to collection.title_or_label, hyrax.collection_path(collection.id) }
    collection_links = []
    links.each_with_index do |link, n|
      collection_links << link
      collection_links << ', ' unless links[n + 1].nil?
    end
    tag.p safe_join([t('hyrax.collection.is_part_of'), ': '] + collection_links), class: 'card-collection-link'
  end

end

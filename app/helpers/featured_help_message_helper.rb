module FeaturedHelpMessageHelper

  def render_featured_help_message(presenter)
    if presenter.class.to_s.include? "Collection"
      featured_class = FeaturedCollection
      featured_string = "collection"
    elsif presenter.class.to_s.include? "Work"
      featured_class = FeaturedWork
      featured_string = "work"
    else
      return
    end
    if !featured_class.can_create_another?
      sanitize('<p class="text-muted feature-' + featured_string + '-message">Maximum of ' +
                   "#{featured_class.feature_limit}" +
                   ' featured ' + featured_string + 's.</p>') + disabled_button
    else # presenter.solr_document.private? => true
      sanitize('<p class="text-muted feature-' + featured_string + '-message">' +
                   featured_string.capitalize + ' must be public.</p>') +
      disabled_button
    end
  end

  def disabled_button
    sanitize('<a class="btn btn-default disabled">Feature</a>')
  end

end

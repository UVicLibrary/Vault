module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior
  # Helpers provided by hyrax-doi plugin.
  include Hyrax::DOI::HelperBehavior
  include Hyku::BlacklightHelperBehavior

  def application_name
    Site.application_name || super
  end

  def institution_name
    Site.institution_name || super
  end

  def institution_name_full
    Site.institution_name_full || super
  end

  def banner_image
    Site.instance.banner_image? ? Site.instance.banner_image.url : super
  end

  # OVERRIDE Hyrax 4.0 to prevent Blacklight Deprecation Warning for #add_facet_params
  def search_state_with_facets(params, facet = {})
    state = Blacklight::SearchState.new(params, CatalogController.blacklight_config)
    return state.params if facet.none?

    # facet should contain one or two values. If it has two values,
    # the second is assumed to be the depositor facet.
    # facet_type = state.add_facet_params(facet.keys.first.to_s + "_sim", facet.values.first)
    facet_type = state.filter(facet.keys.first.to_s + "_sim").add(facet.values.first).params
    return facet_type if facet.length == 1

    # facet_depositor = state.add_facet_params(facet.keys[1].to_s + "_ssim", facet.values[1])
    facet_depositor = state.filter(facet.keys[1].to_s + "_ssim").add(facet.values[1]).params
    facet_all = Hash.new {}
    facet_all["f"] = facet_type["f"].merge(facet_depositor["f"])
    facet_all
  end
  
end

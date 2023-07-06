class FeaturedWorkList
  include ActiveModel::Model

  # @param [ActionController::Parameters] a collection of nested perameters
  def featured_works_attributes=(attributes_collection)
    attributes_collection = attributes_collection.to_h if attributes_collection.respond_to?(:permitted?)
    attributes_collection = attributes_collection.sort_by { |i, _| i.to_i }.map { |_, attributes| attributes } if attributes_collection.is_a? Hash

    attributes_collection.each do |attributes|
      #raise "Missing id" if attributes['id'].blank?
      if FeaturedWork.exists?(attributes['id'])
        existing_record = FeaturedWork.find(attributes['id'])
        existing_record.update(attributes.except('id'))
      else
        attributes_collection.delete(attributes)
      end
    end
  end

  def featured_works
    return @works if @works
    @works = FeaturedWork.all
    add_solr_document_to_works
    @works = @works.reject do |work|
      work.destroy if work.presenter.blank?
      work.presenter.blank?
    end
  end

  delegate :empty?, to: :featured_works

  private

    def add_solr_document_to_works
      work_presenters.each do |presenter|
        work_with_id(presenter.id).presenter = presenter
      end
    end

    def ids
      @works.pluck(:work_id)
    end

    def work_presenters
      ability = nil
      @works ||= FeaturedWork.all
      Hyrax::PresenterFactory.build_for(ids: @works.pluck(:work_id),
                                        presenter_class: presenter_class,
                                        presenter_args: ability)
    end

    def work_with_id(id)
      @works.find { |w| w.work_id == id }
    end

    def presenter_class
      if Settings.multitenancy.enabled
        case Account.find_by(tenant: Apartment::Tenant.current)
        when "vault"
          VaultWorkShowPresenter
        else
          Hyrax::WorkShowPresenter
        end
      else
        VaultWorkShowPresenter
      end
    end
end

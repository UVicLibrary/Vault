# Generated via
#  `rails generate hyrax:work IaffWork`
module Hyrax
  class IaffWorkPresenter < Hyku::WorkShowPresenter
    Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::FileSetPresenter

    delegate :alternative_title, :geographic_coverage, :coordinates, :chronological_coverage, :extent,
             :additional_physical_characteristics, :has_format, :physical_repository, :provenance,
             :provider, :sponsor, :genre, :format, :is_referenced_by, :date_digitized, :transcript,
             :technical_note, :year, to: :solr_document

    # @return FileSetPresenter presenter for the representative FileSets
    # Fix bug where Hyrax couldn't find member presenters for some works
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||=
          begin
            result = member_presenters_for([representative_id]).first
            if doc = ::SolrDocument.find(representative_id)
              if doc._source[:has_model_ssim].first == "FileSet"
                Hyrax::MemberPresenterFactory.file_presenter_class.new(doc, @current_ability, @request)
              end
            elsif result.respond_to?(:representative_presenter)
              return nil if result.try(:id) == id
              result.representative_presenter
            else
              return nil if result.try(:id) == id
              result
            end
          end
    end

    # @return [Hyrax::FileSetPresenter]
    def member_presenter_factory
      Hyrax::MemberPresenterFactory.file_presenter_class = Hyrax::FileSetPresenter
      @member_presenter_factory ||=
        Hyrax::MemberPresenterFactory.new(solr_document, current_ability, request)
    end

    def manifest_url
      "#{manifest_helper.manifest_hyrax_iaff_work_url(self.solr_document.id, host: request.base_url)}"
    end

    def manifest_metadata
      metadata = []
      Hyrax::IaffWorkForm.required_fields.each do |field|
        if Hyrax::WorkShowPresenter.method_defined? field
          metadata << {
              'label' => I18n.t("simple_form.labels.defaults.#{field}"),
              'value' => Array.wrap(send(field))
          }
        else
          metadata << {
              'label' => "#{field.to_s.capitalize}", # I18n.t("simple_form.labels.defaults.#{field}") => translation missing
              'value' => Array.wrap(self.solr_document.send(field))
          }
        end
      end
      metadata
    end


  end
end

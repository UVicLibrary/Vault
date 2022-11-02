# Generated via
#  `rails generate hyrax:work IaffWork`
module Hyrax
  class IaffWorkPresenter < Hyrax::WorkShowPresenter

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

# frozen_string_literal: true
module Hyrax
  # Creates the presenters of the members (member works and file sets) of a specific object
  class MemberPresenterFactory
    class_attribute :file_presenter_class, :work_presenter_class
    # modify this attribute to use an alternate presenter class for the files
    self.file_presenter_class = FileSetPresenter

    # modify this attribute to use an alternate presenter class for the child works
    self.work_presenter_class = WorkShowPresenter

    def initialize(work, ability, request = nil)
      @work = Hyrax::SolrDocument::OrderedMembers.decorate(work)
      @current_ability = ability
      @request = request
    end

    delegate :id, to: :@work
    attr_reader :current_ability, :request

    # @param [Array<String>] ids a list of ids to build presenters for
    # @param [Class] presenter_class the type of presenter to build
    # @return [Array<presenter_class>] presenters for the ordered_members (not filtered by class)
    def member_presenters(ids = ordered_ids, presenter_class = composite_presenter_class)
      PresenterFactory.build_for(ids: ids,
                                 presenter_class: presenter_class,
                                 presenter_args: presenter_factory_arguments)
    end

    # @return [Array<FileSetPresenter>] presenters for the orderd_members that are FileSets
    def file_set_presenters
      @file_set_presenters ||= member_presenters(ordered_ids & file_set_ids)
    end

    # @return [Array<WorkShowPresenter>] presenters for the ordered_members that are not FileSets
    def work_presenters
      @work_presenters ||= member_presenters(ordered_ids - file_set_ids, work_presenter_class)
    end

    def ordered_ids
      @work.ordered_member_ids
    end

    private

    # These are the file sets that belong to this work, but not necessarily
    # in order.
    # Arbitrarily maxed at 10 thousand; had to specify rows due to solr's default of 10
    def file_set_ids
    	        @file_set_ids ||= begin
                                  Hyrax::SolrService.query("{!field f=has_model_ssim}FileSet",
                                                           rows: 10_000,
                                                           fl: Hyrax.config.id_field,
                                                           fq: "{!join from=ordered_targets_ssim to=id}id:\"#{id}/list_source\"")
                                      .flat_map { |x| x.fetch(Hyrax.config.id_field, []) }
                                end
      source_ids = @work.class.to_s.include?("SolrDocument") ? @work._source['file_set_ids_ssim'] : @work.file_set_ids
      # If Solr (source_ids) doesn't have the same contents as Hyrax::SolrService (@file_set_ids)
      if source_ids.nil?
        solr = RSolr.connect url: Account.find_by(tenant: Apartment::Tenant.current).solr_endpoint.url
        response = solr.get 'select', params: {
          q: "*:*",
          rows: 10_000,
          fl: "member_ids_ssim",
          fq: "id:\"#{id}\""
        }
        unless response['response']['docs'].empty? || response['response']['docs'][0].empty?
        	@file_set_ids = response['response']['docs'][0]['file_set_ids_ssim']
        else
        	@file_set_ids
        end
      elsif source_ids.sort != @file_set_ids.sort
        @file_set_ids = source_ids
      else
        @file_set_ids
      end
    end

    def presenter_factory_arguments
      [current_ability, request]
    end

    def composite_presenter_class
      CompositePresenterFactory.new(file_presenter_class, work_presenter_class, ordered_ids & file_set_ids)
    end
  end
end

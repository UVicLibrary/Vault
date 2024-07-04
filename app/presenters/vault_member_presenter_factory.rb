class VaultMemberPresenterFactory < Hyrax::MemberPresenterFactory
  class_attribute :file_presenter_class, :work_presenter_class
  # modify this attribute to use an alternate presenter class for the files
  self.file_presenter_class = VaultFileSetPresenter

  # modify this attribute to use an alternate presenter class for the child works
  self.work_presenter_class = VaultWorkShowPresenter

private

# These are the file sets that belong to this work, but not necessarily
# in order.
# Arbitrarily maxed at 10 thousand; had to specify rows due to solr's default of 10
#
# This assumes that all members of a work are file sets, which is true in Vault.
  def file_set_ids
    @file_set_ids ||= begin
                      proxy_field = 'proxy_in_ssi'
                      target_field = 'ordered_targets_ssim'
                      Hyrax::SolrService.query(
                                                "#{proxy_field}:#{id}",
                                                rows: 10_000,
                                                fl: target_field
                                               )
                                        .flat_map { |x| x.fetch(target_field, []) }
                    end
  end
end
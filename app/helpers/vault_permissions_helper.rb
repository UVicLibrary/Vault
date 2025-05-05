module VaultPermissionsHelper
  # @since Hyrax 4.0.0
  # Checks the permissions and visibility of item (item can be a Collection, GenericWork, or FileSet)
  # Returns True if badges should be displayed and False if not
  def badge_visibility?(item)
    if item.is_a?(Array)
      controller.can?(:edit, item) || item.map(&:visibility).any?(!"open")
    else
      controller.can?(:edit, item) || item.visibility != "open"
    end
  end
end
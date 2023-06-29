# frozen_string_literal: true
class VaultDispatcher < Hyrax::Identifier::Dispatcher

  ##
  # Assigns an identifier to the object.
  #
  #   To assign a DataCite DOI to a work, call the Dispatcher like so:
  #   VaultDispatcher.for(:datacite).assign_for!(object: work)
  #
  # This involves two steps:
  #   - Registering the identifier with the registrar service via `registrar`.
  #   - Storing the new identifier on the object, in the provided `attribute`.
  #
  # @note the attribute for identifier storage must be multi-valued, and will
  #  be overwritten during assignment.
  #

  #
  # @param attribute [Symbol] the attribute in which to store the identifier.
  #   This attribute will be overwritten during assignment.
  # @param object    [ActiveFedora::Base, Hyrax::Resource] the object to assign an identifier.
  #
  # @return [ActiveFedora::Base, Hyrax::Resource] object
  def assign_for(object:, attribute: :doi)
    super
  end

  ##
  # Assigns an identifier and saves the object.
  #
  # @see #assign_for
  def assign_for!(object:, attribute: :doi)
    super
  end

end
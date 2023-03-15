module CdmMigrator
  class CreateAttributesService
    class << self

      # Creates a hash of object attributes for a work or file set from a CSV row


      # @param [Hash] - a parsed CSV row mapped to a hash using CSV.parse(...).map(&:to_hash)
      # @param [Work or FileSet]
      # @param [String] - multi-value separator
      # @return [Hash]
      def call(row, object, mvs = "|")
        # @instance_variable = some variable that you need in other methods
        @object = object
      end

      private

      # Some private methods here. Examples:

      def work_form(worktype = "GenericWork")
        Module.const_get("Hyrax::#{worktype}Form") rescue nil || Module.const_get("Hyrax::Forms::WorkForm")
      end

      def file_form
        Module.const_get("Hyrax::FileSetForm") rescue nil || Module.const_get("Hyrax::Forms::FileSetEditForm")
      end

    end
  end
end
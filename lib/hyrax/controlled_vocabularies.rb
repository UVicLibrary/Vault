module Hyrax
  module ControlledVocabularies
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Location
      autoload :ResourceLabelCaching
      autoload :FastResourceLabelCaching
      autoload :GettyAatLabelCaching
      autoload :Creator
      autoload :Contributor
      autoload :PhysicalRepository
      autoload :Provider
      autoload :Subject
      autoload :GeographicCoverage
      autoload :Genre
    end
  end
end

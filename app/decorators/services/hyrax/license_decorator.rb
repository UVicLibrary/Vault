module Hyrax
  module LicenseDecorator

    def initialize
      super('rights_statements')
    end

  end
end
Hyrax::LicenseService.prepend(Hyrax::LicenseDecorator)
class IaffLanguageService < Hyrax::QaSelectService
	def initialize(_authority_name = nil)
	  super('iaff_language')
	end
end
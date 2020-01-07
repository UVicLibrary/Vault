class IaffGenreService < Hyrax::QaSelectService
	def initialize(_authority_name = nil)
	  super('iaff_genre')
	end
end
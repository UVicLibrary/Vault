class IaffGpsOrEstService < Hyrax::QaSelectService
	def initialize(_authority_name = nil)
	  super('iaff_gps_or_est')
	end
end
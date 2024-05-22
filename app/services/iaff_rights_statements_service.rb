class IaffRightsStatementService < Hyrax::QaSelectService

	def initialize(_authority_name = nil)
	  super('iaff_rights_statements')
	end
	
	mattr_accessor :authority
	self.authority = Qa::Authorities::Local.subauthority_for('iaff_rights_statements')

	
	def self.label(id)
		authority.find(id).fetch('term') rescue id
	end
	
end
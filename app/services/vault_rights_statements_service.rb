class VaultRightsStatementsService < Hyrax::QaSelectService
	def initialize(authority_name = nil)
	  super('vault_rights_statements')
	end
	
	mattr_accessor :authority
	self.authority = Qa::Authorities::Local.subauthority_for('vault_rights_statements')
	
	def self.label(id)
		authority.find(id).fetch('term') rescue id
	end
	
end
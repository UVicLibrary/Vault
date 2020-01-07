class VaultRightsStatementService < Hyrax::QaSelectService
	def initialize(_authority_name = nil)
	  super('vault_rights_statements')
	end
end
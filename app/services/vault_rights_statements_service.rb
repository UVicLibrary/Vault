class VaultRightsStatementsService < Hyrax::QaSelectService
	def initialize(authority_name = nil)
	  super('vault_rights_statements')
	end
end
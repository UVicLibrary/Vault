# OVERRIDE Hyrax 4.0 to add config/metadata/vault_basic_metadata
module Hyrax::ValkyrieFileSetIndexerDecorator

  include Hyrax::Indexer(:vault_basic_metadata)

end
Hyrax::ValkyrieFileSetIndexer.prepend(Hyrax::ValkyrieFileSetIndexerDecorator)
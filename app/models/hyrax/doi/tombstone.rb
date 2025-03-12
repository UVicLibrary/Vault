module Hyrax
  module DOI
    class Tombstone < ApplicationRecord

      validates :doi, presence: true, uniqueness: true
      validates :hyrax_id, presence: true
      validates :reason, presence: true

    end
  end
end
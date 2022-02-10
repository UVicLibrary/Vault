class FeaturedCollection < ApplicationRecord
  FEATURE_LIMIT = 8
  validate :count_within_limit, on: :create
  validates :order, inclusion: { in: proc { 0..FEATURE_LIMIT } }

  attr_accessor :presenter


  default_scope { order(:order) }

  def count_within_limit
    return if FeaturedCollection.can_create_another?
    errors.add(:base, "Limited to #{FEATURE_LIMIT} featured collections.")
  end

  class << self
    def can_create_another?
      FeaturedCollection.count < FEATURE_LIMIT
    end

    def feature_limit
      FEATURE_LIMIT
    end
  end
end

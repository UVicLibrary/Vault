# frozen_string_literal: true
#
# Can be deleted/omitted after upgrading to Hyrax 4.0
# See https://github.com/samvera/hyrax/pull/6003 to support flipflop 2.7.1
#
module Hyrax
  module Admin
    class StrategiesController < Flipflop::StrategiesController
      before_action do
        authorize! :manage, Hyrax::Feature
      end

      # TODO: we could remove this if we used an isolated engine
      def features_url(*args)
        hyrax.admin_features_path(*args)
      end
    end
  end
end
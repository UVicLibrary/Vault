# frozen_string_literal: true
# 
# OVERRIDE Hyrax v.3.5 to use Site.instance.available_works instead of
# Hyrax.config.registered_curation_concern_types.
#
# This file should be deleted after upgrading to Hyku 6 / Hyrax 5 since
# the arguments for the customized methods change.
module Hyrax
    module QuickClassificationQueryDecorator

        # @param [User] user the current user
        # @param [Hash] options
        # @option options [#call] :concern_name_normalizer (String#constantize) a proc that translates names to classes
        # @option options [Array<String>] :models the options to display, defaults to everything.
        def initialize(user, options = {})
          @user = user
          @concern_name_normalizer = options.fetch(:concern_name_normalizer, ->(str) { str.constantize })
          @models = Site.instance.available_works
        end

        # @return true if the requested concerns is same as all avaliable concerns
        def all?
          models == Site.instance.available_works
        end

    end
end
Hyrax::QuickClassificationQuery.prepend(Hyrax::QuickClassificationQueryDecorator)
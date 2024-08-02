# frozen_string_literal: true

# OVERRIDE Hyrax v 3.5. Delete me after upgrading to Hyku v.6.
module Hyrax
  module Admin
    module DashboardPresenterDecorator

      # @return [Fixnum] the number of currently registered users
      def user_count
        ::User.registered.for_repository.without_system_accounts.uniq.count
      end

    end
  end
end

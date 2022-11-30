module Devise
  module Models
    module Authenticatable
      list = %i[
        invitation_token invitation_created_at invitation_sent_at
        invitation_accepted_at invitation_limit invited_by_type
        invited_by_id invitations_count
      ]

      #Old code found under: https://github.com/scambra/devise_invitable/blob/master/lib/devise_invitable/models/authenticatable.rb
      UNSAFE_ATTRIBUTES_FOR_SERIALIZATION.concat(list) #Replacing BLACKLIST_FOR_SERIALIZATION.concat(list)
    end
  end
end
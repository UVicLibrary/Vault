# RSpec
# spec/support/factory_bot.rb
# Comment this out after running spec tests once; Otherwise,
# we get a duplicate definitions error.
require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

# RSpec without Rails
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  # Comment this out after running spec tests once; Otherwise,
  # we get a duplicate definitions error.
  # config.before(:suite) do
  #   FactoryBot.find_definitions
  # end
end
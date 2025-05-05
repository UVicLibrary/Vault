# If you modify this file, be sure to delete the whole assets/sprockets
# from your cache in order to refresh changes.
#
# This is a patch to prevent double-loading of some Hyrax JavaScript assets.
# For some reason, in Rails > 5.4, Sprockets will try to define objects in
# ES6 assets twice using nested callbacks, which eventually throws
# "X is not a constructor" errors in the console.
#
# Since we'll either need to upgrade Sprockets or stop using it fairly soon,
# it doesn't seem worth it to pursue this error any further upstream. Let's
# defer this problem for now until it's time to upgrade.
Sprockets::ES6.class_eval do

  def call(input)
    data = input[:data]
    result = input[:cache].fetch(@cache_key + [input[:filename]] + [data]) do
      transform(data, transformation_options(input))
    end

    # regex = /(define\('#{input[:name]}', \[\'exports', '?.*)/

    # If there is more than one define statement...
    # return if result['code'].start_with?("define('#{input[:name]}', ['exports'], function (exports) {") && result['code'].match?(regex)
    # result['code']
    regex = /(define\(('|")#{input[:name]}('|"), \[('|")exports('|")(, '?.*)?)/

    Rails.logger.warn "input name = #{input[:name]} ; regex count = #{result['code'].scan(regex).count}"

    # If there is more than one define statement...
    return if result['code'].scan(regex).count > 1
    result['code']
  end

end
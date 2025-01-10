# OVERRIDE Blacklight v.7
#
# Our logs are blowing up with Blacklight deprecation warnings
# about params like :utf8 and :locale that can and should be filtered
# out harmlessly by Blacklight anyway. This patch prevents those warnings.
#
Blacklight::Parameters.class_eval do

  private

  def warn_about_deprecated_parameter_handling(params, permitted_params)
    diff = Hashdiff.diff(params.to_unsafe_h, params.permit(*permitted_params).to_h)

    return if diff.empty?
    # If diff only contains keys we want to ignore
    return if (diff.map { |_op, key, *| key } - ignored_params).empty?

    Deprecation.warn(Blacklight::Parameters, "Blacklight 8 will filter out non-search parameter, including: #{diff.map { |_op, key, *| key }.to_sentence}")
  end

  def ignored_params
    %W[utf8 locale]
  end

end
# spammers were blowing up our logs
# this suppresses routing errors
if Rails.env.production?
  class ActionDispatch::DebugExceptions
    alias_method :old_log_error, :log_error
    def log_error(env, wrapper)
      if ignored_error_classes.include? wrapper.exception.class
        return
      else
        old_log_error env, wrapper
      end
    end

    # To ignore an error class in the logs, add it to this array and
    # restart Apache (sudo systemctl restart httpd)
    def ignored_error_classes
      [ActiveFedora::ObjectNotFoundError, ActionController::RoutingError,
       Blacklight::Exceptions::RecordNotFound, Ldp::Gone, FrozenError,
       Riiif::ConversionError, Hyrax::ObjectNotFoundError, ActionController::UnknownFormat,
       Blacklight::Exceptions::InvalidRequest, I18n::InvalidLocale]
    end
  end
end

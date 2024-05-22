if Rails.env.development?
  WebConsole::View.class_eval do
    def render(*)
      super
    end
  end
end

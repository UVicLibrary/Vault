# Override Hyrax 4.0 to add 'sidebar-action-text' to title spans
# Note: Hyku v.6 doesn't seem to need this. Is this still necessary
# after upgrading to Hyku v.6?
module Hyrax
  module CollapsableSectionPresenterDecorator

    def button_tag
      tag.a(role: 'button',
            class: "#{button_class}collapse-toggle nav-link",
            data: { toggle: 'collapse' },
            href: "##{id}",
            onclick: "toggleCollapse(this)",
            'aria-expanded' => open,
            'aria-controls' => id) do
        safe_join([tag.span('', class: icon_class, 'aria-hidden': true),
                   tag.span(text, class: 'sidebar-action-text')], ' ')
      end
    end

  end
end
Hyrax::CollapsableSectionPresenter.prepend(Hyrax::CollapsableSectionPresenterDecorator)
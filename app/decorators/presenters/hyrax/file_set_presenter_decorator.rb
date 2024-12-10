module Hyrax
  module FileSetPresenterDecorator

    delegate :visibility, to: :solr_document

  end
end
Hyrax::FileSetPresenter.prepend(Hyrax::FileSetPresenterDecorator)
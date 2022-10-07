module PaginationHelper

  def show_first_page_link?(current_page)
    Kaminari.config.window >= current_page.to_i
  end

  def show_last_page_link?(current_page, total_pages)
    Kaminari.config.window >= total_pages - current_page.to_i
  end
end

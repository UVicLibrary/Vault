module YearSortHelper

  def render_year_sort(value)
    value.split('-').first
  end

end
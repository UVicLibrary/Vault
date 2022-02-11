module WorkShowHelper

  def work_show_page?
    params[:controller].include? "generic_works"
  end

end
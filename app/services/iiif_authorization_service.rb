class IIIFAuthorizationService
  attr_reader :controller
  def initialize(controller)
    @controller = controller
  end

  def can?(_action, object)
    
    Rails.logger.debug "\n\rCONTROLLER: #{@controller.inspect} \n\r ACTION: #{_action.inspect} \n\r OBJECT: #{object.inspect}"
    controller.current_ability.can?(:show, file_set_id_for(object))
    return true
  end

  private

    def file_set_id_for(object)
    if object.id.include? '/'
      object.id.split('/').first
    else
      URI.decode(object.id).split('/').first
    end
  end
end

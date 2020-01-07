class AuthorityNodeConvertJob < Hyrax::ApplicationJob
  def perform(works, field, authority_service)
    klass = "Hyrax::ControlledVocabularies::#{field.camelize}".constantize
    all_auth = authority_service.camelize.constantize.authority.all
    works.each do |work|
      arr = []
      work.send(field).each do |f|
      	next unless f.is_a? String
      	unless f.include? "http"
      		id = nil
      		all_auth.each do |a|
      			id = a[:id] if a[:term] == f.strip
      		end
      		node = klass.new id
      	else
      		node = klass.new f
      	end
        arr << node
      end
      work.send(field+'=', arr)
      work.save
    end
    
  end
end
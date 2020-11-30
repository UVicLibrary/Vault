class FixityCheckJob < ActiveJob::Base
	
	def perform(works)
		filename = DateTime.now.strftime('%Y%m%d%H%M%S')
		log_file = File.new("/usr/local/rails/vault/log/fixity/#{filename}.log", 'w')
		log_file.puts("Starting Fixity Checking")
		works.each do |w|
			w.file_sets.each do |fs|
				fixity = ActiveFedora::FixityService.new fs.files.first.uri
				unless fixity.check
					log_file.puts("#{fs.id} has a possible corruption")
				end
			end
		end
		log_file.puts("Finished Fixity Checking")
		log_file.close
	end
end
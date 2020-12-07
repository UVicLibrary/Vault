class FixityCheckJob < ActiveJob::Base
	
	def perform(works)
		filename = DateTime.now.strftime('%Y%m%d%H%M%S')
		log_file = File.new("/usr/local/rails/vault/log/fixity/#{filename}.log", 'w')
		log_file.puts("Starting Fixity Checking")
		# Create a list of failed file sets for emailer
		failed = []
		works.each do |w|
			w.file_sets.each do |fs|
				fixity = ActiveFedora::FixityService.new fs.files.first.uri
				unless fixity.check
					log_file.puts("#{fs.id} has a possible corruption")
					failed.push(fs.id)
				end
			end
		end
		log_file.puts("Finished Fixity Checking")
		log_file.close
		# Mail email addresses defined in config/settings.yml
		if failed.any?
			::NotificationMailer.with(file_sets: failed).fixity_failures.deliver
		end
	end
end
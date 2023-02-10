class FixityCheckJob < ActiveJob::Base

	def perform(work_ids)
		filename = DateTime.now.strftime('%Y%m%d%H%M%S')
		log_file = File.new("/usr/local/rails/vault/log/fixity/#{filename}.log", 'w')
		log_file.puts("Starting Fixity Checking")
		# Create a list of failed file sets for emailer
		failed = []
		work_ids.each do |id|
			GenericWork.find(id).file_sets.each do |fs|
				puts fs.id
				# If a file set passed a fixity check within the last month, no need to check again.
				next if passed_recent_check?(fs)
				begin
					fixity = ActiveFedora::FixityService.new fs.latest_content_version.uri
				rescue NoMethodError => error
					log_file.puts "#{fs.id} has no files attached"
					failed.push(fs)
					next
				end
				unless fixity.check
					log_file.puts("#{fs.id} has a possible corruption")
					failed.push(fs)
				end
				fs.last_fixity_check = filename
				fs.save
			end
			log_file.puts("Finished Fixity Checking")
			log_file.close
			# Mail email addresses defined in config/settings.yml
			if failed.any?
				::NotificationMailer.with(file_sets: failed).fixity_failures.deliver
			end
		end
	end

	def passed_recent_check?(file_set)
		return false unless file_set.last_fixity_check.present?
		last_check_date = DateTime.parse(file_set.last_fixity_check)
		(1.month.ago..Time.now).cover?(last_check_date) && passed?(file_set)
	end

	def passed?(file_set)
		log_path = "/usr/local/rails/vault/log/fixity/#{file_set.last_fixity_check}.log"
		return false unless File.file? log_path
		File.read(log_path).exclude?(file_set.id)
	end

end
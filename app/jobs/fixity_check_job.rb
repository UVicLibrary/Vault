class FixityCheckJob < ActiveJob::Base

	def perform(work_ids)
		filename = DateTime.now.strftime('%Y%m%d%H%M%S')
		log_file = File.new("/usr/local/rails/vault/log/fixity/#{filename}.log", 'w')

		# Create a list of failed file sets for emailer
		failed = []
		File.open(log_file, "w+") do |file|
			file.puts("Starting Fixity Checking")
			work_ids.each do |id|
				GenericWork.find(id).file_sets.each do |fs|
					puts fs.id
					# If a file set passed a fixity check within the last month, no need to check again.
					next if passed_recent_check?(fs)
					begin
						fixity = ActiveFedora::FixityService.new fs.latest_content_version.uri
					rescue NoMethodError => error
						file.puts "#{fs.id} has no files attached"
						failed.push(fs)
						next
					end
					unless fixity.check
						file.puts("#{fs.id} has a possible corruption")
						failed.push(fs)
					end
					fs.last_fixity_check = filename
					fs.save
				end
				file.puts("Finished Fixity Checking")
			end
		end
		if failed.any?
			# Mail email addresses defined in config/settings.yml
			::NotificationMailer.with(file_sets: failed).fixity_failures.deliver
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
		File.read(log_path).exclude?(file_set.id) && File.read(log_path).include?("Finished Fixity Checking")
	end

end
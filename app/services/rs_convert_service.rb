class RsConvertService
	
	def self.convert_all
		convert(GenericWork.all)
	end
	
	def self.convert(objects)
		conversion = {
			'http://rightsstatements.org/page/InC/1.0/?language=en' => 'http://rightsstatements.org/vocab/InC/1.0/',
			'http://rightsstatements.org/page/InC-OW-EU/1.0/?language=en' => 'http://rightsstatements.org/vocab/InC-OW-EU/1.0/',
			'http://rightsstatements.org/page/InC-EDU/1.0/?language=en' => 'http://rightsstatements.org/vocab/InC-EDU/1.0/',
			'http://rightsstatements.org/page/InC-NC/1.0/?language=en' => 'http://rightsstatements.org/vocab/InC-NC/1.0/',
			'http://rightsstatements.org/page/InC-RUU/1.0/?language=en' => 'http://rightsstatements.org/vocab/InC-RUU/1.0/',
			'http://rightsstatements.org/page/NoC-CR/1.0/?language=en' => 'http://rightsstatements.org/vocab/NoC-CR/1.0/',
			'http://rightsstatements.org/page/NoC-NC/1.0/?language=en' => 'http://rightsstatements.org/vocab/NoC-NC/1.0/',
			'http://rightsstatements.org/page/NoC-OKLR/1.0/?language=en' => 'http://rightsstatements.org/vocab/NoC-OKLR/1.0/',
			'http://rightsstatements.org/page/NoC-US/1.0/?language=en' => 'http://rightsstatements.org/vocab/NoC-US/1.0/',
			'http://rightsstatements.org/page/CNE/1.0/?language=en' => 'http://rightsstatements.org/vocab/CNE/1.0/',
			'http://rightsstatements.org/page/UND/1.0/?language=en' => 'http://rightsstatements.org/vocab/UND/1.0/',
			'http://rightsstatements.org/page/NKC/1.0/?language=en' => 'http://rightsstatements.org/vocab/NKC/1.0/'
		}
		changed = []
		objects.each do |w|
			save = false
			rs = []
			w.rights_statement.each do |r|
				if(conversion.key?(r))
					save = true
					rs << conversion[r]
				else
					rs << r
				end
			end
			rt = []
			w.resource_type.each do |t|
				if(t.include?("\n"))
					save = true
					rt << t.gsub("\n","")
				else
					rt << t
				end
			end
			if save
				changed << w
				w.rights_statement = rs
				w.resource_type = rt
				w.save
			end
		end
		changed
	end
end
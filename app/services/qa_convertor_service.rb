class QaConvertorService
  
	def self.convert_all
		convert GenericWork.all
	end
	
	def self.convert(objects)
		vocabs = {
			'creator' => Hyrax::ControlledVocabularies::Creator,
			'contributor' => Hyrax::ControlledVocabularies::Contributor,
			'physical_repository' => Hyrax::ControlledVocabularies::PhysicalRepository,
			'provider' => Hyrax::ControlledVocabularies::Provider,
			'subject' => Hyrax::ControlledVocabularies::Subject,
			'geographic_coverage' => Hyrax::ControlledVocabularies::GeographicCoverage,
			'genre' => Hyrax::ControlledVocabularies::Genre,
			'based_near' => Hyrax::ControlledVocabularies::Location
		}
		failed = []
		
		objects.each do |w| 
		
			unless w.contributor.first.nil? || w.contributor.empty?
				if w.contributor.include?('; ')
					w.contributor = w.contributor.first.split('; ') 
				end
			end
			unless w.keyword.first.nil? || w.keyword.empty? 
				if w.keyword.include?(', ')
					w.keyword = w.keyword.first.split(', ') 
				end
			end
			
			vocabs.each do |field, klass|
				a = []
				w.send(field).each do |f|
					unless f.class==String
						a << f
						next
					end
					unless f.include?("http://id.worldcat.org") || f.include?("http://vocab.getty.edu") || f.include?("http://sws.geonames.org")
						a << f
						next
					end
					begin
						a << klass.new(f.strip)
					rescue RuntimeError
						failed << [w, field, f]
					end
				end
				w.send("#{field}=", a)
			end
			begin
				w.save
			rescue
				failed << w
			end
		end
		[failed, objects]
	end
end
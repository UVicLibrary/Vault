RSpec.describe Hyrax::Forms::FileSetEditForm do

  subject { described_class.new(FileSet.new) }

  describe '#terms' do

    it 'returns a list' do
      expect(subject.terms).to eq(
         [:resource_type, :title, :creator, :contributor, :description,
          :keyword, :license, :publisher, :date_created, :subject,
          :language, :identifier, :based_near, :visibility_during_embargo,
          :visibility_after_embargo, :embargo_release_date,
          :visibility_during_lease, :visibility_after_lease,
          :lease_expiration_date, :visibility, :genre, :provider, :format,
          :alternative_title, :geographic_coverage, :coordinates,
          :chronological_coverage, :extent, :identifier,
          :additional_physical_characteristics, :has_format, :physical_repository,
          :provenance, :provider, :sponsor, :genre, :format, :is_referenced_by,
          :date_digitized, :transcript, :technical_note, :year]
      )
    end

    it "doesn't contain fields that users shouldn't be allowed to edit" do
      # date_uploaded is reserved for the original creation date of the record.
      expect(subject.terms).not_to include(:date_uploaded)
    end
  end

  describe '.required_fields' do
    it 'contains only :title' do
      expect(described_class.required_fields).to eq [:title]
    end
  end

  describe '.primary_terms' do
    it 'contains :title, description, :transcript' do
      expect(described_class.primary_terms).to eq [:title, :description, :transcript]
    end
  end

  describe '.secondary_terms' do
    it 'contains all the same fields as a GenericWork' do
      expect(described_class.secondary_terms).to eq [:resource_type, :creator,
       :contributor, :keyword, :license, :publisher, :date_created, :subject,
       :language, :identifier, :based_near, :genre, :provider, :format,
       :alternative_title, :geographic_coverage, :coordinates, :chronological_coverage,
       :extent, :identifier, :additional_physical_characteristics, :has_format,
       :physical_repository, :provenance, :provider, :sponsor, :genre, :format,
       :is_referenced_by, :date_digitized, :technical_note, :year]
    end
  end

  describe '.build_permitted_params' do
    it 'includes controlled vocab attributes' do
      expect(described_class.build_permitted_params).to eq [
         {:resource_type=>[]}, {:title=>[]}, {:creator=>[]}, {:contributor=>[]},
         {:description=>[]}, {:keyword=>[]}, {:license=>[]}, {:publisher=>[]},
         {:date_created=>[]}, {:subject=>[]}, {:language=>[]}, {:identifier=>[]},
         {:based_near=>[]}, :visibility_during_embargo, :visibility_after_embargo,
         :embargo_release_date, :visibility_during_lease, :visibility_after_lease,
         :lease_expiration_date, :visibility, {:genre=>[]}, {:provider=>[]},
         {:format=>[]}, {:alternative_title=>[]}, {:geographic_coverage=>[]},
         {:coordinates=>[]}, {:chronological_coverage=>[]}, {:extent=>[]},
         {:identifier=>[]}, {:additional_physical_characteristics=>[]},
         {:has_format=>[]}, {:physical_repository=>[]}, {:provenance=>[]},
         {:provider=>[]}, {:sponsor=>[]}, {:genre=>[]}, {:format=>[]},
         {:is_referenced_by=>[]}, {:date_digitized=>[]}, {:transcript=>[]},
         {:technical_note=>[]}, {:year=>[]},
         {:permissions_attributes=>[:type, :name, :access, :id, :_destroy]},
         {:creator_attributes=>[:id, :_destroy], :contributor_attributes=>[:id, :_destroy],
          :physical_repository_attributes=>[:id, :_destroy],
          :provider_attributes=>[:id, :_destroy], :subject_attributes=>[:id, :_destroy],
          :geographic_coverage_attributes=>[:id, :_destroy],
          :genre_attributes=>[:id, :_destroy], :transcript=>[]}
      ]
    end
  end

  describe '.model_attributes' do
    let(:params) do
      ActionController::Parameters.new(
          title: ['foo'],
          "visibility" => "on-campus",
          "visibility_during_embargo" => "restricted",
          "embargo_release_date" => "2015-10-21",
          "visibility_after_embargo" => "open",
          "visibility_during_lease" => "open",
          "lease_expiration_date" => "2015-10-21",
          "visibility_after_lease" => "restricted"
      )
    end

    subject { described_class.model_attributes(params) }

    it 'changes only the title' do
      expect(subject['title']).to eq ['foo']
      expect(subject['visibility']).to eq('on-campus')
      expect(subject['visibility_during_embargo']).to eq('restricted')
      expect(subject['visibility_after_embargo']).to eq('open')
      expect(subject['embargo_release_date']).to eq('2015-10-21')
      expect(subject['visibility_during_lease']).to eq('open')
      expect(subject['visibility_after_lease']).to eq('restricted')
      expect(subject['lease_expiration_date']).to eq('2015-10-21')
    end
  end


end
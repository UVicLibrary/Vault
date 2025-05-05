# frozen_string_literal: true

RSpec.describe Hyrax::Forms::FileSetForm do
  subject(:form) { described_class.new(file_set) }
  let(:file_set) { Hyrax::FileSet.new }

  # Replaces / is identical to FileSetEditForm.terms
  describe '.fields' do
    its(:fields) { is_expected.to have_key('additional_physical_characteristics') }
    its(:fields) { is_expected.to have_key('alternative_title') }
    its(:fields) { is_expected.to have_key('based_near') }
    its(:fields) { is_expected.to have_key('chronological_coverage') }
    its(:fields) { is_expected.to have_key('contributor') }
    its(:fields) { is_expected.to have_key('coordinates') }
    its(:fields) { is_expected.to have_key('creator') }
    its(:fields) { is_expected.to have_key('date_created') }
    its(:fields) { is_expected.to have_key('date_digitized') }
    its(:fields) { is_expected.to have_key('description') }
    its(:fields) { is_expected.to have_key('extent') }
    its(:fields) { is_expected.to have_key('has_format') }
    its(:fields) { is_expected.to have_key('genre') }
    its(:fields) { is_expected.to have_key('geographic_coverage') }
    its(:fields) { is_expected.to have_key('has_format') }
    its(:fields) { is_expected.to have_key('identifier') }
    its(:fields) { is_expected.to have_key('is_referenced_by') }
    its(:fields) { is_expected.to have_key('keyword') }
    its(:fields) { is_expected.to have_key('language') }
    its(:fields) { is_expected.to have_key('license') }
    its(:fields) { is_expected.to have_key('physical_repository') }
    its(:fields) { is_expected.to have_key('provenance') }
    its(:fields) { is_expected.to have_key('provider') }
    its(:fields) { is_expected.to have_key('provider') }
    its(:fields) { is_expected.to have_key('publisher') }
    its(:fields) { is_expected.to have_key('resource_type') }
    its(:fields) { is_expected.to have_key('sponsor') }
    its(:fields) { is_expected.to have_key('subject') }
    its(:fields) { is_expected.to have_key('technical_note') }
    its(:fields) { is_expected.to have_key('title') }
    its(:fields) { is_expected.to have_key('transcript') }
  end

  # Replaces / is identical to FileSetEditForm.required_fields
  describe '.required_fields' do
    it 'lists the fields tagged required' do
      expect(described_class.required_fields)
        .to contain_exactly(:title)
    end
  end

  describe '#embargo_release_date' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.embargo_release_date }
                    .from(nil)
      end
    end
  end

  describe '#lease_expiration_date' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.lease_expiration_date }
                    .from(nil)
      end
    end
  end

  describe '#required' do
    it 'requires title' do
      expect(form.required?(:title)).to eq true
    end
  end

  describe '.primary_terms' do
    it 'contains :title, description, :transcript' do
      expect(form.primary_terms).to contain_exactly(:title, :description, :transcript)
    end
  end

  describe '.secondary_terms' do
    it 'contains similar fields to GenericWork' do
      expect(form.secondary_terms).to contain_exactly(:resource_type, :creator,:contributor, :keyword, :license,
                                                      :publisher, :date_created, :subject, :language,
                                                      :based_near, :genre, :provider, :alternative_title,
                                                      :geographic_coverage, :coordinates, :chronological_coverage,
                                                      :extent, :identifier, :additional_physical_characteristics,
                                                      :has_format, :physical_repository, :provenance, :sponsor,
                                                      :is_referenced_by, :date_digitized, :technical_note)
    end
  end

  describe '#visibility_after_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_embargo }
                    .from(nil)
      end
    end
  end

  describe '#visibility_during_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_embargo }
                    .from(nil)
      end
    end
  end

  describe '#visibility_after_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_lease }
                    .from(nil)
      end
    end
  end

  describe '#visibility_during_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_lease }
                    .from(nil)
      end
    end
  end
end
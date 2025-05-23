# frozen_string_literal: true
FactoryBot.define do
  factory :file_set do
    transient do
      user { create(:user) }
      content { nil }
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key
    end

    after(:create) do |file, evaluator|
      Hydra::Works::UploadFileToFileSet.call(file, evaluator.content) if evaluator.content
    end

    trait :public do
      read_groups { ["public"] }
    end

    trait :registered do
      read_groups { ["registered"] }
    end

    trait :image do
      content { File.open(Hyrax::Engine.root + 'spec/fixtures/world.png') }
    end

    trait :pdf do
      content { File.open(Rails.root + 'spec/fixtures/issue_01_combined.pdf') }
    end

    trait :with_original_file do
      after(:create) do |file_set, _evaluator|
        Hydra::Works::AddFileToFileSet
            .call(file_set, File.open(Hyrax::Engine.root + 'spec/fixtures/world.png'), :original_file)
      end
    end

    trait :with_pdf_file do
      after(:create) do |file_set, _evaluator|
        Hydra::Works::AddFileToFileSet
          .call(file_set, File.open(Rails.root + 'spec/fixtures/issue_01_combined.pdf'), :original_file)
      end
    end

    factory :file_with_work do
      after(:build) do |file, _evaluator|
        file.title = ['testfile']
      end
      after(:create) do |file, evaluator|
        Hydra::Works::UploadFileToFileSet.call(file, evaluator.content) if evaluator.content
        work = build(:work, user: evaluator.user)
        work.members << file
        work.ordered_members << file
        work.save!
      end
    end
  end
end

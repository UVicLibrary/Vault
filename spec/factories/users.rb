FactoryBot.define do
  factory :base_user, class: User do
    sequence(:email) { |_n| "email-#{srand}@test.com" }
    password { 'a password' }
    password_confirmation { 'a password' }

    factory :user do
      after(:create) { |user| user.remove_role(:admin) }
    end

    factory :admin do
      after(:create) do |user|
        user.add_role(:admin, Site.instance)
        # user.site_roles = ["admin"]
      end
    end

    factory :uvic do
      after(:create) do |user|
        user.add_role(:uvic)
        user.site_roles = ["uvic"]
      end
    end

    factory :superadmin do
      after(:create) { |user| user.add_role(:superadmin) }
    end

    factory :invited_user do
      after(:create, &:invite!)
    end

    trait :guest do
      guest { true }
    end
  end
end

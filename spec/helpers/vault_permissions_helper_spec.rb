RSpec.describe VaultPermissionsHelper do
  include Devise::Test::IntegrationHelpers
  let(:ability) { Ability.new(user) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    sign_in(user)
  end

  let(:work){
  create(:work,
         visibility: visibility,
         edit_groups:['admin'],
         depositor: 'egetty@uvic.ca'
  )}
  let(:collection){
    create(:collection,
           visibility: visibility,
           edit_groups:['admin'],
           depositor: 'egetty@uvic.ca')
  }
  let(:fileset){
    create(:file_set,
           visibility: visibility,
           edit_groups:['admin'],
           depositor: 'egetty@uvic.ca')
  }

  # Testing for collections
  context 'with a public collection' do
    let(:visibility){"open"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(collection)).to be_truthy
      end
    end

    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is false' do
        expect(badge_visibility?(collection)).to be_falsey
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is false' do
        expect(badge_visibility?(collection)).to be_falsey
      end
    end
  end

  context 'with an institution-only collection' do
    let(:visibility){"authenticated"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(collection)).to be_truthy
      end
    end

    # Public user may have access through campus IP
    # Test does not account for IP range
    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is true' do
        expect(badge_visibility?(collection)).to be_truthy
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is true' do
        expect(badge_visibility?(collection)).to be_truthy
      end
    end
  end

  context 'with a private collection' do
    let(:visibility){"restricted"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(collection)).to be_truthy
      end
    end

    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is true' do
        expect(badge_visibility?(collection)).to be_truthy
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is true' do
        expect(badge_visibility?(collection)).to be_truthy
      end
    end
  end

  # Testing for works
  context 'with a public work' do
    let(:visibility){"open"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(work)).to be_truthy
      end
    end

    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is false' do
        expect(badge_visibility?(work)).to be_falsey
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is false' do
        expect(badge_visibility?(work)).to be_falsey
      end
    end
  end

  context 'with an institution-only work' do
    let(:visibility){"authenticated"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(work)).to be_truthy
      end
    end

    # Public user may have access through campus IP
    # Test does not account for IP range
    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is true' do
        expect(badge_visibility?(work)).to be_truthy
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is true' do
        expect(badge_visibility?(work)).to be_truthy
      end
    end
  end

  context 'with a private work' do
    let(:visibility){"restricted"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(work)).to be_truthy
      end
    end

    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is true' do
        expect(badge_visibility?(work)).to be_truthy
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is true' do
        expect(badge_visibility?(work)).to be_truthy
      end
    end
  end

  # Testing for FileSets
  context 'with a public fileset' do
    let(:visibility){"open"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(fileset)).to be_truthy
      end
    end

    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is false' do
        expect(badge_visibility?(fileset)).to be_falsey
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is false' do
        expect(badge_visibility?(fileset)).to be_falsey
      end
    end
  end
  
  context 'with an institution-only fileset' do
    let(:visibility){"authenticated"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(fileset)).to be_truthy
      end
    end

    # Public user may have access through campus IP
    # Test does not account for IP range
    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is true' do
        expect(badge_visibility?(fileset)).to be_truthy
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is true' do
        expect(badge_visibility?(fileset)).to be_truthy
      end
    end
  end

  context 'with a private fileset' do
    let(:visibility){"restricted"}
    context 'with an admin user' do
      let(:user){create(:admin)}
      it 'is true' do
        expect(badge_visibility?(fileset)).to be_truthy
      end
    end

    context 'not signed in (public user)' do
      let(:user){create(:user)}
      it 'is true' do
        expect(badge_visibility?(fileset)).to be_truthy
      end
    end

    context 'as a Uvic user' do
      let(:user){create(:uvic)}
      it 'is true' do
        expect(badge_visibility?(fileset)).to be_truthy
      end
    end
  end
end

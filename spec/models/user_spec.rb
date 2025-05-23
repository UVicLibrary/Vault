RSpec.describe User, type: :model do
  context 'the first created user in global tenant' do
    subject { FactoryBot.create(:base_user) }

    before do
      allow(Account).to receive(:global_tenant?).and_return true
    end

    it 'does not get the admin role' do
      expect(subject.persisted?).to eq true
      expect(subject).not_to have_role :admin
    end
  end

  context 'the first created user on a tenant' do
    subject { FactoryBot.create(:base_user) }

    context 'in development' do
      before { allow(Rails.env).to receive(:development?).and_return true }

      it 'is given the admin role' do
        expect(subject.persisted?).to eq true
        expect(subject).to have_role :admin, Site.instance
      end
    end

    context 'in other environments (prod or test)' do

      it 'is not given the admin role' do
        expect(subject.persisted?).to eq true
        expect(subject).not_to have_role :admin, Site.instance
      end
    end
  end

  context 'a subsequent user' do
    let!(:first_user) { FactoryBot.create(:base_user) }
    let!(:next_user) { FactoryBot.create(:base_user) }

    it 'does not get the admin role' do
      expect(next_user.persisted?).to eq true
      expect(next_user).not_to have_role :admin
    end
  end

  describe '#site_roles' do
    subject { FactoryBot.create(:admin) }

    it 'fetches the global roles assigned to the user' do
      expect(subject.site_roles.pluck(:name)).to match_array ['admin']
    end
  end

  describe '#site_roles=' do
    subject { FactoryBot.create(:user) }

    it 'assigns global roles to the user' do
      expect(subject.site_roles.pluck(:name)).to be_empty

      subject.update(site_roles: ['admin'])

      expect(subject.site_roles.pluck(:name)).to match_array ['admin']
    end

    it 'removes roles' do
      subject.update(site_roles: ['admin'])
      subject.update(site_roles: [])
      expect(subject.site_roles.pluck(:name)).to be_empty
    end
  end
end
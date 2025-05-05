RSpec.describe 'hyrax/base/_work_title.html.erb', type: :view do
  let(:ability) { double }
  let(:generic_work) { GenericWork.new(
    :title => ['My Title'],
    :id => '123',
    :visibility => visibility,
    edit_groups:['admin'],
    depositor: 'egetty@uvic.ca'
  ) }
  let(:presenter) { VaultWorkShowPresenter.new(generic_work, ability) }

  before do
    sign_in(user)
  end

  context 'with a public work' do
    let(:visibility){"open"}
    # Test admin user
    context 'signed in as admin user' do
      let(:user) {FactoryBot.create(:admin)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(true)
      end
      it 'displays public badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to have_css '.badge-success', text: 'Public', exact_text: true
      end
    end

    # Test UVic user
    context 'as uvic user' do
      let(:user) {FactoryBot.create(:uvic)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(false)
      end
      it 'does not display public badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to_not have_css '.badge-success', text: 'Public', exact_text: true
      end
    end

    # Test public
    context 'as public user' do
      let(:user) {FactoryBot.create(:user)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(false)
      end
      it 'does not display public badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to_not have_css '.badge-success', text: 'Public', exact_text: true
      end
    end
  end

  # With an institution work
  context 'with an institution work' do
    let(:visibility){"authenticated"}
    # Test admin user
    context 'signed in as admin user' do
      let(:user) {FactoryBot.create(:admin)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(true)
      end
      it 'displays institution badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to have_css '.badge-info', text: 'Institution', exact_text: true
      end
    end

    # Test UVic user
    context 'as uvic user' do
      let(:user) {FactoryBot.create(:uvic)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(true)
      end
      it 'displays institution badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to have_css '.badge-info', text: 'Institution', exact_text: true
      end
    end

    # Test public
    context 'as public user' do
      let(:user) {FactoryBot.create(:user)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(true)
      end
      it 'displays institution badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to have_css '.badge-info', text: 'Institution', exact_text: true
      end
    end
  end

  # Test private work
  context 'with a private work' do
    let(:visibility){"restricted"}
    # Test admin user
    context 'signed in as admin user' do
      let(:user) {FactoryBot.create(:admin)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(true)
      end
      it 'displays private badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to have_css '.badge-danger', text: 'Private', exact_text: true
      end
    end

    # Test UVic user
    context 'as uvic user' do
      let(:user) {FactoryBot.create(:uvic)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(true)
      end
      it 'displays private badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to have_css '.badge-danger', text: 'Private', exact_text: true
      end
    end

    # Test public
    context 'as public user' do
      let(:user) {FactoryBot.create(:user)}
      before do
        allow(view).to receive(:badge_visibility?).with(generic_work).and_return(true)
      end
      it 'displays private badge' do
        render('work_title', presenter: presenter)

        expect(rendered).to have_css '.badge-danger', text: 'Private', exact_text: true
      end
    end
  end
end
RSpec.describe 'hyrax/collections/_show_document_list.html.erb', type: :view do
  let(:documents) { [GenericWork.new(
    :title => ['My Title'],
    :id => '123',
    :visibility => visibility,
    edit_groups:['admin'],
    depositor: 'egetty@uvic.ca'
  ) , "Hello", "World"] }
  let(:collection){ ["Hello", "World"] }

  before do
    assign(:collection, collection)
    sign_in(user)
    stub_template('hyrax/collections/_show_document_list_row.html.erb' => "<%= document %>")
  end

  context 'with a public document' do
    let(:visibility){"open"}
    # Test admin user
    context 'signed in as admin user' do
      let(:user) {FactoryBot.create(:admin)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(true)
      end
      it 'displays public badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to have_selector 'th', text: 'Visibility', exact_text: true
      end
    end

    # Test UVic user
    context 'as uvic user' do
      let(:user) {FactoryBot.create(:uvic)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(false)
      end
      it 'displays public badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to_not have_selector 'th', text: 'Visibility', exact_text: true
      end
    end

    # Test public
    context 'as public user' do
      let(:user) {FactoryBot.create(:user)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(false)
      end
      it 'displays public badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to_not have_selector 'th', text: 'Visibility', exact_text: true
      end
    end
  end

  context 'with an institution document' do
    let(:visibility){"authenticated"}
    # Test admin user
    context 'signed in as admin user' do
      let(:user) {FactoryBot.create(:admin)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(true)
      end
      it 'displays institution badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to have_selector 'th', text: 'Visibility', exact_text: true
      end
    end

    # Test UVic user
    context 'as uvic user' do
      let(:user) {FactoryBot.create(:uvic)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(true)
      end
      it 'displays institution badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to have_selector 'th', text: 'Visibility', exact_text: true
      end
    end

    # Test public
    context 'as public user' do
      let(:user) {FactoryBot.create(:user)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(true)
      end
      it 'displays institution badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to have_selector 'th', text: 'Visibility', exact_text: true
      end
    end
  end

  context 'with a private document' do
    let(:visibility){"restricted"}
    # Test admin user
    context 'signed in as admin user' do
      let(:user) {FactoryBot.create(:admin)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(true)
      end
      it 'displays restricted badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to have_selector 'th', text: 'Visibility', exact_text: true
      end
    end

    # Test UVic user
    context 'as uvic user' do
      let(:user) {FactoryBot.create(:uvic)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(true)
      end
      it 'displays restricted badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to have_selector 'th', text: 'Visibility', exact_text: true
      end
    end

    # Test public
    context 'as public user' do
      let(:user) {FactoryBot.create(:user)}
      before do
        allow(view).to receive(:badge_visibility?).with(collection).and_return(true)
      end
      it 'displays restricted badge' do
        render('hyrax/collections/show_document_list.html.erb', documents: documents)

        expect(rendered).to have_selector 'th', text: 'Visibility', exact_text: true
      end
    end
  end
end
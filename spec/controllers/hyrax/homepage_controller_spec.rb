# frozen_string_literal: true
RSpec.describe Hyrax::HomepageController, type: :controller do
  routes { Hyrax::Engine.routes }

  describe "#index" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    context 'with existing featured researcher' do
      let!(:frodo) { ContentBlock.create!(name: ContentBlock::NAME_REGISTRY[:researcher], value: 'Frodo Baggins', created_at: Time.zone.now) }

      it 'finds the featured researcher' do
        get :index
        expect(response).to be_successful
        expect(assigns(:featured_researcher)).to eq frodo
      end
    end

    context 'with no featured researcher' do
      it "sets featured researcher" do
        get :index
        expect(response).to be_successful
        assigns(:featured_researcher).tap do |researcher|
          expect(researcher).to be_kind_of ContentBlock
          expect(researcher.name).to eq 'featured_researcher'
        end
      end
    end

    it "sets marketing text" do
      get :index
      expect(response).to be_successful
      assigns(:marketing_text).tap do |marketing|
        expect(marketing).to be_kind_of ContentBlock
        expect(marketing.name).to eq 'marketing_text'
      end
    end

    it "does not include other user's private documents in recent documents" do
      get :index
      expect(response).to be_successful
      titles = assigns(:recent_documents).map { |d| d['title_tesim'][0] }
      expect(titles).not_to include('Test Private Document')
    end

    it "includes only Work objects in recent documents" do
      get :index
      expect(assigns(:recent_documents).all?(&:work?)).to eq true
    end

    context "with a document not created this second", clean_repo: true do
      before do
        gw3 = GenericWork.new(title: ['Test 3 Document'], read_groups: ['public'])
        gw3.apply_depositor_metadata('mjg36')
        # stubbing to_solr so we know we have something that didn't create in the current second
        old_to_solr = gw3.method(:to_solr)
        allow(gw3).to receive(:to_solr) do
          old_to_solr.call.merge(
              "system_create_dtsi" => 1.day.ago.strftime("%FT%TZ"),
              "date_uploaded_dtsi" => 1.day.ago.strftime("%FT%TZ")
          )
        end
        gw3.save
      end

      it "sets recent documents in the right order" do
        get :index
        expect(response).to be_successful
        expect(assigns(:recent_documents).length).to be <= 4
        create_times = assigns(:recent_documents).map { |d| d['date_uploaded_dtsi'] }
        expect(create_times).to eq create_times.sort.reverse
      end
    end

    context "with collections" do
      let(:presenter) { double }
      let(:repository) { double }
      let(:collection_results) { double(documents: ['collection results']) }

      before do
        allow(controller).to receive(:repository).and_return(repository)
        allow(controller).to receive(:search_results).and_return([nil, ['recent document']])
        allow_any_instance_of(Hyrax::CollectionsService).to receive(:search_results).and_return(collection_results.documents)
      end

      it "initializes the presenter with ability and a list of collections" do
        expect(Hyrax::HomepagePresenter).to receive(:new).with(Ability,
                                                               ["collection results"])
                                                .and_return(presenter)
        get :index
        expect(response).to be_successful
        expect(assigns(:presenter)).to eq presenter
      end
    end

    context "with featured works" do
      let!(:my_work) { create(:work, user: user) }

      before do
        FeaturedWork.create!(work_id: my_work.id)
      end

      it "sets featured works" do
        get :index
        expect(response).to be_successful
        expect(assigns(:featured_work_list)).to be_kind_of FeaturedWorkList
      end
    end

    it "sets announcement content block" do
      get :index
      expect(response).to be_successful
      assigns(:announcement_text).tap do |announcement|
        expect(announcement).to be_kind_of ContentBlock
        expect(announcement.name).to eq 'announcement_text'
      end
    end

    context "without solr" do
      before do
        allow_any_instance_of(Hyrax::SearchService).to receive(:search_results).and_raise Blacklight::Exceptions::InvalidRequest
      end

      it "errors gracefully" do
        get :index
        expect(response).to be_successful
        expect(assigns(:admin_sets)).to be_blank
        expect(assigns(:recent_documents)).to be_blank
      end
    end

    # CUSTOM behavior described in app/decorators/controllers/hyrax/homepage_decorator.rb
    context "with 'vault' in the base_url" do

      let(:account) { Account.new(cname: "vault.library.uvic.ca") }

      before do
        request.host = "vault.library.uvic.ca"
        allow(Account).to receive(:find_by).with({tenant: "public"}).and_return(account)
      end

      it 'sets an @response' do
        get :index
        expect(response).to be_successful
        expect(assigns(:response)).to be_kind_of(Blacklight::Solr::Response)
      end

      context 'with works' do

        before do
          gw3 = GenericWork.new(title: ['Test 3 Document'], read_groups: ['public'])
          gw3.apply_depositor_metadata('mjg36')
          gw3.save!
        end

        it 'sets @work_count to the total number of works' do
          get :index
          expect(response).to be_successful
          expect(assigns(:work_count)).to eq(1)
        end
      end

      context "with featured collections" do
        let!(:my_collection) { create(:collection, title: ['Title']) }

        before do
          FeaturedCollection.create!(collection_id: my_collection.id)
        end

        it "sets featured collections" do
          get :index
          expect(response).to be_successful
          expect(assigns(:featured_collection_list)).to be_kind_of FeaturedCollectionList
        end
      end

      context 'with 9 or more collections' do

        let(:mock_collections) {
          [*1..9].each_with_object([]) do |num, array|
            array.push(SolrDocument.new(id: num.to_s))
          end
        }

        before do
          # https://www.rubydoc.info/github/rspec/rspec-mocks/RSpec%2FMocks%2FMessageExpectation:and_wrap_original
          allow(Hyrax::PresenterFactory).to receive(:build_for).and_wrap_original do |_, args, _|
            args[:ids].map { |id| args[:presenter_class].new(SolrDocument.new(id: id), "public") }
          end
          allow_any_instance_of(Hyrax::HomepagePresenter).to receive(:collections).and_return(mock_collections)
        end

        describe 'sets recent collection presenters' do
          it 'only takes the first 8 results' do
            get :index
            expect(response).to be_successful
            expect(assigns(:recent_collection_presenters).count).to eq(8)
            expect(assigns(:recent_collection_presenters).map(&:to_s)).not_to include("9")
          end
        end

      end

      context 'with more than 9 recent works' do
        describe 'sets recent work presenters' do

          let(:mock_works) {
            [*1..9].each_with_object([]) do |num, array|
              array.push(SolrDocument.new(id: num.to_s))
            end
          }
          pending
        end
      end

      describe 'building collection list presenters' do
        # Stub create_date so that we can expect Hyrax::PresenterFactory NOT to receive ['foo-c','foo-a','foo-b']
        # from #recent_collection_presenters.
        let(:collection_results) { [SolrDocument.new(id: "foo-c",
                                                     title_tesim: ["C Title"],
                                                     system_create_dtsi: 1.days.ago.strftime("%FT%TZ")),
                                    SolrDocument.new(id: "foo-a",
                                                     title_tesim: ["A Title"],
                                                     system_create_dtsi: 3.days.ago.strftime("%FT%TZ")),
                                    SolrDocument.new(id: "foo-b",
                                                     title_tesim: ["B Title"],
                                                     system_create_dtsi: 2.days.ago.strftime("%FT%TZ"))] }

        before do
          allow_any_instance_of(Hyrax::CollectionsService).to receive(:search_results).and_return(collection_results)
          allow(Hyrax::PresenterFactory).to receive(:build_for).and_call_original
        end

        it 'sorts them alphabetically by title' do
          get :index
          expect(response).to be_successful
          expect(Hyrax::PresenterFactory).to have_received(:build_for).with({ ids: ['foo-a','foo-b','foo-c'],
                                                                        presenter_args: nil,
                                                                        presenter_class: Hyrax::CollectionPresenter })
          expect(Hyrax::PresenterFactory).not_to have_received(:build_for).with({ ids: ['foo-c','foo-a','foo-b'],
                                                                        presenter_args: nil,
                                                                        presenter_class: Hyrax::CollectionPresenter })
        end
      end

    end
  end
end

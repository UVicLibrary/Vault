RSpec.describe HyraxHelper, type: :helper do
  describe "#banner_image" do
    context "with uploaded banner image" do
      before do
        f = fixture_file_upload('images/nypl-hydra-of-lerna.jpg', 'image/jpg')
        Site.instance.update(banner_image: f)
      end

      it "returns the uploaded banner image" do
        expect(helper.banner_image).to eq(Site.instance.banner_image.url)
      end
    end

    context "without uploaded banner image" do
      it "returns the configured Hyrax banner image" do
        expect(helper.banner_image).to eq(Hyrax.config.banner_image)
      end
    end
  end

  describe "#thumbnail_label_for" do
    it "gives a string even if no thumbnail label can be found" do
      expect(helper.thumbnail_label_for(object: Object.new)).to be_a String
    end

    it 'interoperates with CollectionForm' do
      collection = ::Collection.new
      collection.thumbnail = ::FileSet.create(title: ["thumbnail"])

      form = Hyrax::Forms::CollectionForm.new(collection,
                                              :FAKE_ABILITY,
                                              :FAKE_BLACKLIGHT_REPOSITORY)

      expect(helper.thumbnail_label_for(object: form)).to eq 'thumbnail'
    end

    it 'interoperates with AdminSetForm' do
      admin_set = AdminSet.new
      admin_set.thumbnail = ::FileSet.create(title: ["thumbnail"])

      form = Hyrax::Forms::AdminSetForm.new(admin_set,
                                            :FAKE_ABILITY,
                                            :FAKE_BLACKLIGHT_REPOSITORY)

      expect(helper.thumbnail_label_for(object: form)).to eq 'thumbnail'
    end
  end
end

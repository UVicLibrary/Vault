RSpec.describe Hyrax::InheritCollectionVisibilityJob do
  let(:collection) { create(:collection, visibility: "restricted") }
  let(:member_works) { [public_work, institution_work, private_work] }

  let(:public_work) { create(:generic_work, visibility: "open", doi_status_when_public: "findable") }
  let(:public_fs) { FileSet.new(visibility: 'open') }

  let(:institution_work) { create(:generic_work, visibility: "authenticated") }
  let(:institution_fs) { FileSet.new(visibility: "authenticated") }

  let(:private_work) { create(:generic_work, visibility: "restricted") }
  let(:private_fs) { FileSet.new(visibility: "restricted") }

  before do
    # Set up relationships between collections, works, file_sets
    allow(GenericWork).to receive(:where).with(member_of_collection_ids_ssim: collection.id).and_return(member_works)
    allow(public_work).to receive(:members).and_return([public_fs])
    allow(institution_work).to receive(:members).and_return([institution_fs])
    allow(private_work).to receive(:members).and_return([private_fs])
    # Stub to prevent errors when checking if the mailer has been called later
    allow(VisibilityPermissionsMailer).to receive(:with).with(any_args).and_call_original
  end

  context "when visibility is set to open" do
    it "does not save public works or file sets" do
      expect(public_work).not_to receive(:save!)
      expect(public_fs).not_to receive(:save!)
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "open", "example.com")
    end

    it "changes the visibility of non-public objects to public, and saves them" do
      expect(institution_work).to receive(:save!)
      expect(institution_fs).to receive(:save!)
      expect(private_work).to receive(:save!)
      expect(private_fs).to receive(:save!)
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "open", "example.com")
      expect([collection.reload, public_work, public_fs, institution_work, institution_fs,
              private_work, private_fs].map(&:visibility)).to all(eq("open"))
    end

    it "sets works' doi_status_when_public to findable" do
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "open", "example.com")
      expect([institution_work, private_work].pluck(:doi_status_when_public)).to all(eq "findable")
    end

    it "enqueues a Hyrax::DOI::RegisterDOIJob for each work that it updates" do
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "open", "example.com")
      expect(Hyrax::DOI::RegisterDOIJob).to have_been_enqueued.exactly(2).times
    end

    it "calls the VisibilityPermissionsMailer with the correct arguments" do
      expect(VisibilityPermissionsMailer).to receive(:with).with(account_host: "example.com", user_email: "test@example.com", id: collection.id, visibility: "open")
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "open", "example.com")
    end
  end

  context "when visibility is set to authenticated" do
    it "does not save authenticated works or file sets" do
      expect(institution_work).not_to receive(:save!)
      expect(institution_fs).not_to receive(:save!)
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "authenticated", "example.com")
    end

    it "changes the visibility of non-authenticated objects to authenticated, and saves them" do
      expect(public_work).to receive(:save!)
      expect(public_fs).to receive(:save!)
      expect(private_work).to receive(:save!)
      expect(private_fs).to receive(:save!)
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "authenticated", "example.com")
      expect([collection.reload, public_work, public_fs, institution_work, institution_fs,
              private_work, private_fs].map(&:visibility)).to all(eq("authenticated"))
    end

    it "enqueues a Hyrax::DOI::RegisterDOIJob for each work that it updates" do
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "authenticated", "example.com")
      expect(Hyrax::DOI::RegisterDOIJob).to have_been_enqueued.exactly(2).times
    end

    it "sets works' doi_status_when_public to findable" do
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "authenticated", "example.com")
      expect([public_work, private_work].pluck(:doi_status_when_public)).to all(eq "findable")
    end

    it "calls the VisibilityPermissionsMailer with the correct arguments" do
      expect(VisibilityPermissionsMailer).to receive(:with).with(account_host: "example.com", user_email: "test@example.com", id: collection.id, visibility: "authenticated")
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "authenticated", "example.com")
    end
  end

  context "when visibility is set to restricted" do
    let(:collection) { create(:collection, visibility: "open") }

    it "does not save private works or file sets" do
      expect(private_work).not_to receive(:save!)
      expect(private_fs).not_to receive(:save!)
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "restricted", "example.com")
    end

    it "changes the visibility of non-restricted objects to restricted, and saves them" do
      expect(public_work).to receive(:save!)
      expect(public_fs).to receive(:save!)
      expect(institution_work).to receive(:save!)
      expect(institution_fs).to receive(:save!)
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "restricted", "example.com")
      expect([collection.reload, public_work, public_fs, institution_work, institution_fs,
              private_work, private_fs].map(&:visibility)).to all(eq("restricted"))
    end

    it "enqueues a Hyrax::DOI::RegisterDOIJob for each work that it updates" do
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "restricted", "example.com")
      expect(Hyrax::DOI::RegisterDOIJob).to have_been_enqueued.exactly(2).times
    end

    it "sets works' doi_status_when_public to findable" do
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "restricted", "example.com")
      expect([institution_work, public_work].pluck(:doi_status_when_public)).to all(eq "findable")
    end

    it "calls the VisibilityPermissionsMailer with the correct arguments" do
      expect(VisibilityPermissionsMailer).to receive(:with).with(account_host: "example.com", user_email: "test@example.com", id: collection.id, visibility: "restricted")
      Hyrax::InheritCollectionVisibilityJob.perform_now(collection.id, "test@example.com", "restricted", "example.com")
    end
  end
end
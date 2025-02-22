RSpec.describe BatchExport::ExportFileJob do

  let(:work) { create(:work_with_one_file) }
  let(:file_set) { work.file_sets.first }
  let(:export_path) { Rails.root.join('tmp').to_s }
  let(:collection) { create(:collection_lw) }

  describe '#perform' do

    before do
      work.member_of_collections = [collection]
      work.save!
      perform_enqueued_jobs do
        IngestLocalFileJob.perform_now(file_set, "#{fixture_path}/issue_01_combined.pdf", create(:user))
      end
      file_set.reload
    end

    it 'exports the bag with the expected contents' do
      described_class.perform_now(file_set, export_path)
      expect(File).to exist("#{export_path}/#{file_set.id}.7z")

      # Extract the bag contents so we can inspect them
      `7z x -y #{export_path}/#{file_set.id}.7z -o#{export_path}/#{file_set.id}`

      # See app/jobs/batch_export/export_file_job.rb for details on expected contents

      # Checks that all the expected files are present
      bag_contents = ["work_and_file_set_metadata.csv", "#{file_set.id}.txt", "bagit.txt", "data",
                      "collection_uuids_and_titles.txt", "tagmanifest-sha1.txt", "manifest-sha1.txt",
                      "bag-info.txt", "tagmanifest-md5.txt"]
      expect(Dir.glob("#{export_path}/#{file_set.id}/*").map { |filepath| File.basename(filepath) }).to match_array(bag_contents)

      # Exported the actual objects and recorded the checksum
      expect(File).to exist("#{export_path}/#{file_set.id}/data/objects/#{file_set.id}.pdf")
      expect(File).to exist("#{export_path}/#{file_set.id}/data/objects/bitstream_#{file_set.id}")
      expect(File.read("#{export_path}/#{file_set.id}/manifest-sha1.txt")).to include(file_set.characterization_proxy.checksum.value)

      # Characterization metadata
      included_keywords = ["mime_type: application/pdf", "fixity_check_status", "last_modified",
                           "path_on_local_drive", "page_count", "file_size", "md5_checksum"]
      expect(included_keywords.all? { |keyword| File.read("#{export_path}/#{file_set.id}/data/metadata.txt").include?(keyword) }).to eq true

      # Collection relationships
      expect(File.read("#{export_path}/#{file_set.id}/collection_uuids_and_titles.txt")).to include collection.title.first
      expect(File.read("#{export_path}/#{file_set.id}/collection_uuids_and_titles.txt")).to include collection.id
    end

    after do
      FileUtils.rm("#{export_path}/#{file_set.id}.7z")
      FileUtils.rm_rf("#{export_path}/#{file_set.id}")
    end
  end

end
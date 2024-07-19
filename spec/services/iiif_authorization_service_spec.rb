# frozen_string_literal: true
RSpec.describe IIIFAuthorizationService do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:controller) { Riiif::ImagesController.new }
  let(:service) { described_class.new(controller) }
  let(:file_set_id) { 'mp48sc763' }
  let(:image_id) { "#{file_set_id}/files/0b957460-99b4-4c31-902f-0fc23eefb972" }
  let(:image) { Riiif::Image.new(image_id) }
  let(:referer) { nil }
  let(:size) { 'full,full' }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(controller.request).to receive(:referer).and_return(referer)
    allow(controller).to receive(:params).and_return(size: size)
  end

  describe "#can?" do

    context "when the user doesn't have read access to the FileSet" do

      before do
        allow(ability).to receive(:test_read).with(file_set_id).and_return(false)
        allow(ability).to receive(:test_download).with(file_set_id).and_return(false)
      end

      context 'when requesting an image' do
        context "info" do
          subject { service.can?(:info, image) }

          it { is_expected.to be false }
        end

        context "show" do
          subject { service.can?(:show, image) }

          it { is_expected.to be false }
        end
      end

      context 'when requesting a thumbnail' do
        context 'work thumbnail' do
          let(:size) { "!150,300" }
          context "show" do
            subject { service.can?(:show, image) }
            it { is_expected.to be true }
          end
        end
      end
    end

    context 'when the user has read access but not download access to the FileSet' do
      subject { service.can?(:show, image) }

      before do
        allow(ability).to receive(:test_read).with(file_set_id).and_return(true)
        allow(ability).to receive(:test_download).with(file_set_id).and_return(false)
      end

      context 'when requesting a thumbnail' do

        context 'work thumbnail' do
          let(:size) { "!150,300" }
          context "show" do
            it { is_expected.to be true }
          end
        end
      end

      context 'when requesting a full image' do
        context "show" do
          it { is_expected.to be false }
        end
      end

      context 'when on a universal viewer page' do
        let(:referer) { "http://example.com/uv/uv-no-download.html" }
        context "show" do
          it { is_expected.to be true }
        end
      end

    end

    context 'when the user has download access to the FileSet' do
      let(:user) { create(:admin) }

      context "show" do
        subject { service.can?(:show, image) }

        it { is_expected.to be true }
      end
    end
  end

  describe "#file_set_id_for" do
    let(:image_id) { "#{file_set_id}%2Ffiles%2F70e3f592-e23a-4841-a434-ba5abc6e2892" }

    it "escapes URLs before parsing the file set id" do
      expect(service.send(:file_set_id_for, image)).to eq file_set_id
    end
  end
end

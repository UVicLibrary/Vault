# frozen_string_literal: true
RSpec.describe IIIFAuthorizationService do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:controller) { Riiif::ImagesController.new }
  let(:service) { described_class.new(controller) }
  let(:file_set_id) { 'mp48sc763' }
  let(:image_id) { "#{file_set_id}/files/0b957460-99b4-4c31-902f-0fc23eefb972" }
  let(:image) { Riiif::Image.new(image_id) }

  before { allow(controller).to receive(:current_ability).and_return(ability) }

  describe "#can?" do
    context "when the user has read access to the FileSet" do
      before { allow(ability).to receive(:test_read).with(file_set_id).and_return(true) }

      context "info" do
        subject { service.can?(:info, image) }

        it { is_expected.to be true }
      end

      context "show" do
        subject { service.can?(:show, image) }

        it { is_expected.to be true }
      end
    end

    context "when the user doesn't have read access to the FileSet" do
      before { allow(ability).to receive(:test_read).with(file_set_id).and_return(false) }

      context "info" do
        subject { service.can?(:info, image) }

        it { is_expected.to be false }
      end

      context "show" do
        subject { service.can?(:show, image) }

        it { is_expected.to be false }
      end
    end

    context 'when the user has read access but not download access to the FileSet' do
      subject { service.can?(:show, image) }

      before do
        allow(ability).to receive(:test_read).with(file_set_id).and_return(true)
        allow(ability).to receive(:test_download).with(file_set_id).and_return(false)
        allow(controller).to receive(:action_name).and_return('show')
      end

      context 'when requesting a thumbnail' do
        before { allow(controller).to receive(:params).and_return(size: size) }

        context 'work thumbnail' do
          let(:size) { IIIFThumbnailPaths::THUMBNAIL_SIZE }

          context "show" do
            it { is_expected.to be true }
          end
        end

        context 'collection or card thumbnail' do
          let(:size) { LargeIIIFThumbnailPaths::LARGE_THUMBNAIL_SIZE }

          context "show" do
            it { is_expected.to be true }
          end
        end

      end

      context 'when on a work page' do
        let(:controller) { Hyrax::GenericWorksController.new }

        context "show" do
          it { is_expected.to be true }
        end

      end

      context 'when requesting a full image' do
        before { allow(controller).to receive(:params).and_return(size: size) }
        let(:size) { 'full,full' }

        context "show" do
          it { is_expected.to be false }
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
end

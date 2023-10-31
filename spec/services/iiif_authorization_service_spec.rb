# frozen_string_literal: true
RSpec.describe IIIFAuthorizationService do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }

  let(:controller) { Riiif::ImagesController.new }
  let(:request) { double(remote_ip: "111.111.11.11") }

  let(:service) { described_class.new(controller) }
  let(:file_set_id) { 'mp48sc763' }
  let(:image_id) { "#{file_set_id}/files/0b957460-99b4-4c31-902f-0fc23eefb972" }
  let(:image) { Riiif::Image.new(image_id) }

  let(:document) { SolrDocument.new(id: file_set_id) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(controller).to receive(:request).and_return(request)
    allow(SolrDocument).to receive(:find).with(file_set_id).and_return(document)
  end

  describe "#can?" do

    context "when the user has read access to the FileSet" do

      before do
        allow(controller).to receive(:ip_on_campus?).and_return(false)
        allow(ability).to receive(:test_read).with(file_set_id).and_return(true)
      end

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

      context 'and IP is not on campus' do
        before { allow(controller).to receive(:ip_on_campus?).and_return(false) }

        context "info" do
          subject { service.can?(:info, image) }

          it { is_expected.to be false }
        end

        context "show" do
          subject { service.can?(:show, image) }

          it { is_expected.to be false }
        end
      end

      context "and IP is on campus" do

        before do
          allow(document).to receive(:visibility).and_return("authenticated")
          allow(Settings).to receive(:to_hash).and_return({ allowed_ip_ranges: ["111.111.11.11"] })
        end

        context "info" do
          subject { service.can?(:info, image) }

          it { is_expected.to be true }
        end

        context "show" do
          subject { service.can?(:show, image) }

          it { is_expected.to be true }
        end

      end
    end
  end
end

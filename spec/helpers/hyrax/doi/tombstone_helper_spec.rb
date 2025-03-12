# frozen_string_literal: true
RSpec.describe Hyrax::DOI::TombstoneHelper do
  let(:creator) {
    {
      "creator" => { "creatorName" => "Doe, Jane, 1900-2000" }
    }
  }
  let(:metadata) {
    {
      "identifier" => { "identifierType" => "DOI", "__content__"=>"10.1234/abcd-efgh" },
      "creators" => creator,
      "contributors" => { "contributor" => { "contributorName" => { "__content__" => "Contributor" } } },
      "titles" => { "title" => "Title" },
      "publisher" => "UVic Libraries",
      "publicationYear" => "2025"
    }
  }

  subject { helper.build_citation(metadata) }

  before { allow(helper).to receive(:params).and_return(doi: "10.1234/abcd-efgh") }

  describe "#build_citation" do

    context 'with less than 3 creators' do
      it { is_expected.to eq "Doe, Jane. <em>Title</em>. UVic Libraries, 2025, doi: https://doi.org/10.1234/abcd-efgh." }
    end

    context 'with 3 or more creators/contributors' do
      let(:creator) { { "creator" => [{ "creatorName"=> { "nameType" => "Personal", "__content__"=>"Doe, Jane" } },
                                      { "creatorName"=> { "nameType" => "Organizational", "__content__"=>"Creator 2" } },
                                      { "creatorName"=> { "nameType" => "Organizational", "__content__"=>"Creator 3" } }] } }

      it { is_expected.to eq "Doe, Jane, et al. <em>Title</em>. UVic Libraries, 2025, doi: https://doi.org/10.1234/abcd-efgh." }
    end

    context 'with no creator' do
      let(:creator) { { "creator" => { "creatorName" => ":Unav" } } }

      it { is_expected.to eq "<em>Title</em>. UVic Libraries, 2025, doi: https://doi.org/10.1234/abcd-efgh." }
    end

  end

end
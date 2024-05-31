require 'rails_helper'

RSpec.describe 'creating a new tenant', multitenant: true do
  include ActiveJob::TestHelper

  let(:user) { FactoryBot.create(:superadmin) }

  before do
    login_as(user, scope: :user)
    Capybara.default_host = "http://#{Account.admin_host}"
  end

  it 'sets up the new tenant', :cleanup_accounts do
    visit '/'
    click_link 'Get Started'

    fill_in 'Short name', with: 'some-random-name'
    click_on 'Save'

    account = Account.find_by(cname: 'some-random-name.localhost')
    expect(account.solr_endpoint.url).not_to be_blank
    expect(account.fcrepo_endpoint.base_path).not_to be_blank
    expect(account.redis_endpoint.namespace).not_to be_blank

    account.switch do
      expect(AdminSet.count).to eq 1
    end
  end

  after do
    account = Account.find_by(cname: 'some-random-name.localhost')
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = true
    CleanupAccountJob.perform_now(account)
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs = false
  end

end

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'webmock/rspec'
require 'rspec/rails'
require 'i18n/debug' if ENV['I18N_DEBUG']

require 'shoulda/matchers'
require 'shoulda/callback/matchers'
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# ensure Hyrax::Schema gets loaded is resolvable for `support/` models
Hyrax::Schema # rubocop:disable Lint/Void

Valkyrie::MetadataAdapter
    .register(Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter)

require 'hyrax/specs/shared_specs/factories/strategies/json_strategy'
require 'hyrax/specs/shared_specs/factories/strategies/valkyrie_resource'
FactoryBot.register_strategy(:valkyrie_create, ValkyrieCreateStrategy)
FactoryBot.register_strategy(:json, JsonStrategy)
FactoryBot.definition_file_paths = [File.expand_path("../factories", __FILE__)]

query_registration_target =
    Valkyrie::MetadataAdapter.find(:test_adapter).query_service.custom_queries
[Hyrax::CustomQueries::Navigators::CollectionMembers,
 Hyrax::CustomQueries::Navigators::ChildFilesetsNavigator,
 Hyrax::CustomQueries::Navigators::ChildWorksNavigator,
 Hyrax::CustomQueries::FindAccessControl,
 Hyrax::CustomQueries::FindCollectionsByType,
 Hyrax::CustomQueries::FindManyByAlternateIds,
 Hyrax::CustomQueries::FindIdsByModel,
 Hyrax::CustomQueries::FindFileMetadata,
 Hyrax::CustomQueries::Navigators::FindFiles].each do |handler|
  query_registration_target.register_query_handler(handler)
end

RSpec.configure do |config|
  config.before(:suite) do
    # WebMock.disable_net_connect!(allow_localhost: true, allow: 'hyku-carrierwave-test.s3.amazonaws.com')
    WebMock.allow_net_connect!
  end

  # Require supporting ruby files from spec/support/ and subdirectories.  Note: engine, not Rails.root context.
  # Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }
  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  # Exclude certain directories that are known to be failing
  # config.exclude_pattern = 'spec/{features,requests,tasks,views}/**/*_spec.rb'
  # config.exclude_pattern = 'spec/features/**/*_spec.rb'

  config.include Devise::Test::IntegrationHelpers, type: :request

  config.include Capybara::RSpecMatchers, type: :input
  config.include InputSupport, type: :input

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.

  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # only run aws tests from CI (or w/ `--tag aws`) and only run it on the main repo, since that
  # is where the valid aws keys live. TRAVIS_PULL_REQUEST_SLUG is "" when the job is a push job
  unless ENV['CI'] &&
    (ENV['TRAVIS_PULL_REQUEST_SLUG'].match('samvera-labs/hyku') || ENV['TRAVIS_PULL_REQUEST_SLUG'].blank?)
    config.filter_run_excluding(aws: true)
  end

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = 'tmp/spec_examples.txt'

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Give us a full backtrace on Travis-CI
  config.backtrace_exclusion_patterns = [] if ENV['CI']

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end

  ActiveJob::Base.queue_adapter = :test

  # Use this example metadata when you want to perform jobs inline during testing.
  #
  #   describe '#my_method`, :perform_enqueued do
  #     ...
  #   end
  #
  # If you pass an `Array` of job classes, they will be treated as the filter list.
  #
  #   describe '#my_method`, perform_enqueued: [MyJobClass] do
  #     ...
  #   end
  #
  # Limit to specific job classes with:
  #
  #   ActiveJob::Base.queue_adapter.filter = [JobClass]
  #
  config.around(:example, :perform_enqueued) do |example|
    ActiveJob::Base.queue_adapter.filter =
        example.metadata[:perform_enqueued].try(:to_a)
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = true
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true

    example.run

    ActiveJob::Base.queue_adapter.filter = nil
    ActiveJob::Base.queue_adapter.perform_enqueued_jobs    = false
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = false
  end

  config.after(:example, :cleanup_accounts) do |example|
    FcrepoEndpoint.all.each(&:remove!)
    SolrEndpoint.all.each(&:remove!)
    RedisEndpoint.all.each(&:remove!)

    Account.all.each do |account|
      Apartment::Tenant.drop(account.tenant) rescue nil  # ignore if account.tenant missing
      account.destroy
    end
  end

  config.before(:example, :index_adapter) do |example|
    allow(Hyrax.config)
        .to receive(:query_index_from_valkyrie)
                .and_return(true)

    adapter_name = example.metadata[:index_adapter]

    allow(Hyrax)
        .to receive(:index_adapter)
                .and_return(Valkyrie::IndexingAdapter.find(adapter_name))
  end

  config.after(:example, :index_adapter) do |example|
    adapter_name = example.metadata[:index_adapter]
    Valkyrie::IndexingAdapter.find(adapter_name).wipe!
  end

  config.before(:example, :valkyrie_adapter) do |example|
    adapter_name = example.metadata[:valkyrie_adapter]

    allow(Hyrax)
        .to receive(:metadata_adapter)
                .and_return(Valkyrie::MetadataAdapter.find(adapter_name))
  end

  # turn on the default nested reindexer; we use a null implementation for most
  # tests because it's (supposedly?) much faster. why is it faster but doesn't
  # impact most tests? maybe we should fix this in the implementation instead?
  config.around(:example, :with_nested_reindexing) do |example|
    original_indexer = Hyrax.config.nested_relationship_reindexer
    Hyrax.config.nested_relationship_reindexer =
        Hyrax.config.default_nested_relationship_reindexer
    example.run
    Hyrax.config.nested_relationship_reindexer = original_indexer
  end

  # A search for collection members returns empty without this line because
  # of the way CollectionMemberSearchBuilder filters by work models
  Hyrax.config.register_curation_concern Hyrax::Test::SimpleWorkLegacy

end

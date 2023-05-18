yml_config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access
redis_config = yml_config.merge(thread_safe: true)

Sidekiq.configure_server do |config|
	config.redis = redis_config
	#config.server_middleware do |chain|
		#chain.add Sidekiq::Middleware::Server::RetryJobs, :max_retries => 4
	#end

  config.on(:startup) do
    schedule_file = "config/schedule.yml"

    if File.exist?(schedule_file)
      Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end


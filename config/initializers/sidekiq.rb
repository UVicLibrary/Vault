yml_config = YAML.load(ERB.new(IO.read(Rails.root + 'config' + 'redis.yml')).result)[Rails.env].with_indifferent_access
redis_config = yml_config.merge(thread_safe: true)

Sidekiq.configure_server do |config|
	config.redis = redis_config
	#config.server_middleware do |chain|
		#chain.add Sidekiq::Middleware::Server::RetryJobs, :max_retries => 4
	#end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end


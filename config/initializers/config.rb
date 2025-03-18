# config/initializers/config.rb
require 'dry/configurable'
require 'yaml'

module WeatherConfig
  extend Dry::Configurable

  # infra config
  setting :api_endpoint, default: 'https://api.openweathermap.org/data/2.5/weather'
  setting :cache_ttl, default: 1800 # 30 minutes
  setting :concurrency, default: 5
  setting :log_level, default: 'info'

  # cache config
  setting :redis_url, default: 'redis://localhost:6379/0'
  setting :redis_max_connections, default: 5

  # env config
  env = ENV.fetch('RACK_ENV', 'development')
  config_path = File.expand_path("../environments/#{env}.yml", __dir__)
  
  if File.exist?(config_path)
    config.update(YAML.load_file(config_path))
  end
end
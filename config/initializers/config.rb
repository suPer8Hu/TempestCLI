# config/initializers/config.rb
require 'dry/configurable'

module WeatherConfig
  extend Dry::Configurable

  # infra config
  setting :api_endpoint, default: 'https://api.openweathermap.org/data/2.5/weather'
  setting :cache_ttl, default: 1800 # 30 minutes
  setting :concurrency, default: 5

  # env config
  env = ENV.fetch('RACK_ENV', 'development')
  config_paths = Dir[File.join(__dir__, '../environments', "#{env}.yml")]
  Dry::Configurable::Loaders::YAML.new(config_paths).call do |key, value|
    set(key, value)
  end
end
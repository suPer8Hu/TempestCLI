require 'redis'
require 'json'

module Weather
  class Cache
    def initialize(options = {})
      @ttl = options[:ttl] || WeatherConfig.config.cache_ttl || 1800
      redis_url = ENV['REDIS_URL'] || 'redis://localhost:6379/0'
      @redis = Redis.new(url: redis_url)
    end

    def fetch(key, &block)
      cache_key = "weather:#{key}"
      
      # fetch from the cache
      cached_data = @redis.get(cache_key)
      
      if cached_data
        puts "🎯 Fetch from cache".green if WeatherConfig.config.log_level == 'debug'
        return JSON.parse(cached_data)
      end
      
      # if miss
      puts "🌐 Fetch data from API".yellow if WeatherConfig.config.log_level == 'debug'
      fresh_data = yield
      
      # store the data in the cacche
      @redis.setex(cache_key, @ttl, fresh_data.to_json)
      
      fresh_data
    rescue Redis::BaseError => e
      puts "⚠️ Redis cache error: #{e.message}".red if WeatherConfig.config.log_level == 'debug'
      yield
    end
    
    def clear(key = nil)
      if key
        @redis.del("weather:#{key}")
      else
        # clear all weather cache data
        keys = @redis.keys("weather:*")
        @redis.del(*keys) unless keys.empty?
      end
    rescue Redis::BaseError => e
      puts "⚠️ cache clear failed: #{e.message}".red
    end
    
    def stats
      {
        keys: @redis.keys("weather:*").size,
        memory: @redis.info["used_memory_human"],
        uptime: @redis.info["uptime_in_seconds"]
      }
    rescue Redis::BaseError => e
      { error: e.message }
    end
  end
end
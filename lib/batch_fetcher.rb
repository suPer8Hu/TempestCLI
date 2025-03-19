require 'typhoeus'
require_relative './weather'

class BatchFetcher
  def initialize(cities)
    @cities = cities
    @cache = Weather::Cache.new
  end

  def fetch_all
    # setting the max concurrency requests
    hydra = Typhoeus::Hydra.new(max_concurrency: WeatherConfig.config.concurrency || 5)
    
    # Create requests and associate cache keys for each city
    requests = {}
    @cities.each do |city|
      cache_key = generate_cache_key(city)
      
      # check cache
      cached_data = check_cache(cache_key)
      if cached_data
        requests[city] = { cached: true, data: cached_data }
      else
        requests[city] = { 
          cached: false, 
          request: create_request(city),
          cache_key: cache_key
        }
      end
    end
    
    # push non-cache requests into queue
    requests.each do |city, info|
      hydra.queue(info[:request]) if info[:request]
    end
    
    # run all the requests
    hydra.run
    
    # handle res
    results = {}
    requests.each do |city, info|
      if info[:cached]
        puts "🎯 Use cached data: #{city}".green
        results[city] = info[:data]
      else
        data = parse_response(info[:request].response)
        # cache successed resp
        if data.is_a?(Hash) && (data['cod'] == '200' || data['cod'] == 200)
          @cache.fetch(info[:cache_key]) { data }
        end
        results[city] = data
      end
    end
    
    results
  end

  private

  def create_request(city)
    puts "🌐 Fetch data from API: #{city}".yellow
    
    Typhoeus::Request.new(
      WeatherConfig.config.api_endpoint,
      params: {
        q: city,
        appid: ENV['OPENWEATHER_API_KEY'],
        units: 'metric'
      },
      timeout: 15
    )
  end

  def parse_response(response)
    return { 'error' => "Request failed: #{response.code}", 'cod' => response.code } unless response.success?
    
    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      { 'error' => "Invalid response data", 'cod' => 500 }
    end
  end
  
  def generate_cache_key(city)
    query_string = "q=#{city}"
    "#{query_string}|#{WeatherConfig.config.api_endpoint}"
  end
  
  def check_cache(key)
    cached_data = @cache.instance_variable_get(:@redis).get("weather:#{key}")
    return nil unless cached_data
    
    JSON.parse(cached_data)
  rescue
    nil
  end
end
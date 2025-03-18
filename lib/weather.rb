require 'httparty'
require 'colorize'
require 'date'
require 'time'
require_relative '../config/initializers/api_keys'
require_relative '../config/initializers/config.rb'
require_relative './cache.rb'

class WeatherFetcher
#   API_BASE = "https://api.openweathermap.org/data/2.5/forecast"

  def initialize(city_name_or_id, use_id: false)
    @query = use_id ? { id: city_name_or_id } : { q: city_name_or_id }
    @city = city_name_or_id
    @cache = Weather::Cache.new
  end

  def fetch
    cache_key = generate_cache_key
    
    data = @cache.fetch(cache_key) do
      response = HTTParty.get(WeatherConfig.config.api_endpoint, query: @query.merge(
        appid: ENV['OPENWEATHER_API_KEY'],
        units: 'metric'
      ))
      
      response.parsed_response
    end
    
    data
  end

  def clear_cache
    @cache.clear(generate_cache_key)
  end

  def handle_response(data)
    if data.is_a?(Hash) && (data['cod'] == '200' || data['cod'] == 200)
      display_success(data)
    else
      display_error(data)
    end
  end

  private

  def generate_cache_key
    # generate unique key
    query_string = @query.map { |k, v| "#{k}=#{v}" }.sort.join('&')
    "#{query_string}|#{WeatherConfig.config.api_endpoint}"
  end

  def display_success(data)
    puts "📅 #{data['city']['name']} 5 days weather forecast：".green
    # geet the local time
    local_timezone = Time.now.zone
    
    data['list'].each do |forecast|
      time_utc = Time.parse(forecast['dt_txt'] + ' UTC')
      time_local = time_utc.localtime  
      temp = forecast['main']['temp']
      desc = forecast['weather'].first['description'].capitalize
    
      desc_icon = case forecast['weather'].first['main']
                  when 'Clear' then '☀️'
                  when 'Clouds' then '☁️'
                  when 'Rain' then '🌧️'
                  else '🌤️'
                  end
      
      puts "#{desc_icon} [#{time_local.strftime('%Y-%m-%d %H:%M')}] #{temp}°C | #{desc}".cyan
    end
  end

  def display_error(response)
    if response.is_a?(HTTParty::Response)
      # HTTParty resp
      puts "❌ Error：#{response['message']}".red
      puts "HTTP Status：#{response.code}".red
    else
      # cache data
      puts "❌ Error：#{response['message']}".red
      puts "HTTP Status：#{response['cod']}".red
    end
  end
end
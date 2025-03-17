require 'httparty'
require 'colorize'
require 'date'
require 'time'
require_relative '../config/initializers/api_keys'

class WeatherFetcher
  API_BASE = "https://api.openweathermap.org/data/2.5/forecast"

  def initialize(city_name_or_id, use_id: false)
    @query = use_id ? { id: city_name_or_id } : { q: city_name_or_id }
  end

  def fetch
    response = HTTParty.get(API_BASE, query: @query.merge(
    appid: ENV['OPENWEATHER_API_KEY'],
    units: 'metric'
    ))

    handle_response(response)
  end

  private

  def handle_response(response)
    if response.code == 200
      display_success(response.parsed_response)
    else
      display_error(response)
    end
  end

  def display_success(data)
    puts "📅 #{data['city']['name']} 5日天气预报：".green
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
    puts "❌ Error：#{response['message']}".red
    puts "HTTP Status：#{response.code}".red
  end
end
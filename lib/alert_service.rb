require 'rufus-scheduler'
require 'yaml'
require_relative './subscription_service'

module Weather
  class AlertService
    def initialize
      @scheduler = Rufus::Scheduler.new
      @subscription_service = Weather::SubscriptionService.new
      @monitored_cities = Set.new
    end
    
    # monitoring a specific city
    def monitor(city)
      return if @monitored_cities.include?(city.downcase)
      
      @monitored_cities.add(city.downcase)
      
      # instant check
      check_city(city)
      
      # Check at regular intervals
      @scheduler.every '30m' do
        check_city(city)
      end
      
      puts "🔍 Weather conditions for #{city} have been monitored (checked every 30 minutes)".green
    end
    
    # Get all monitored cities
    def monitored_cities
      @monitored_cities.to_a
    end
    
    # Check all monitored cities immediately.
    def check_all_now
      if @monitored_cities.empty?
        puts "⚠️ Cities not under surveillance".yellow
        return
      end
      
      puts "🔄 The city that is checking all the surveillance....".blue
      @monitored_cities.each do |city|
        check_city(city)
      end
      puts "✅ Inspection completed".green
    end
    
    # Monitor all subscribed cities
    def monitor_all_subscribed
      cities = Set.new
      
      # Get all alert keys in Redis
      alert_keys = @subscription_service.instance_variable_get(:@redis).keys("weather:alert:*")
      
      alert_keys.each do |key|
        city = key.gsub("weather:alert:", "")
        cities.add(city) if !city.empty?
      end
      
      if cities.empty?
        puts "⚠️ No cities are subscribed".yellow
        return
      end
      
      cities.each do |city|
        monitor(city)
      end
    end
    
    private
    
    def check_city(city)
      begin
        puts "🔍 Check weather conditions for #{city}...".blue
        data = WeatherFetcher.new(city).fetch
        
        if data.nil? || !data.is_a?(Hash) || (data['cod'] != '200' && data['cod'] != 200)
          puts "❌ Unable to get data for #{city}".red
          return
        end
        
        check_temperature_alerts(city, data)
        check_precipitation_alerts(city, data)
        check_wind_alerts(city, data)
        check_visibility_alerts(city, data)
      rescue => e
        puts "❌ Error checking #{city}: #{e.message}".red
      end
    end
    
    def check_temperature_alerts(city, data)
      # Temperature check (take the temperature of the first forecast point)
      if data['list'] && !data['list'].empty?
        temp = data['list'].first['main']['temp']
        
        if temp > alert_rules['temperature']['max']
          message = "Current temperature #{temp}°C，exceeding the high temperature warning threshold #{alert_rules['temperature']['max']}°C"
          @subscription_service.send_alert(city, message, "High temperature warning")
          
        elsif temp < alert_rules['temperature']['min']
          message = "Current temperature #{temp}°C，below the low temperature warning threshold #{alert_rules['temperature']['min']}°C"
          @subscription_service.send_alert(city, message, "Low temperature warning")
        end
      end
    end
    
    def check_precipitation_alerts(city, data)
      # Precipitation check
      if data['list'] && !data['list'].empty?
        precipitation = 0
        
        # Get precipitation
        if data['list'].first['rain'] && data['list'].first['rain']['3h']
          precipitation = data['list'].first['rain']['3h'] / 3.0  # Conversion to hourly precipitation
        end
        
        if precipitation > alert_rules['precipitation']['danger']
          message = "Current precipitation #{precipitation}mm/h，reaching heavy rainfall levels"
          @subscription_service.send_alert(city, message, "Heavy rainfall warning!")
          
        elsif precipitation > alert_rules['precipitation']['warning']
          message = "Current precipitation #{precipitation}mm/h，reaching rainfall levels"
          @subscription_service.send_alert(city, message, "Rainfall warning!")
        end
      end
    end
    
    def check_wind_alerts(city, data)
      # wind 
      if data['list'] && !data['list'].empty?
        wind_speed = data['list'].first['wind']['speed']
        
        if wind_speed > alert_rules['wind']['storm']
          message = "Current wind speed #{wind_speed}m/s，reaching storm level."
          @subscription_service.send_alert(city, message, "Storm warning!")
          
        elsif wind_speed > alert_rules['wind']['strong']
          message = "Current wind speed #{wind_speed}m/s，reaching gale force winds"
          @subscription_service.send_alert(city, message, "Wind warning!")
        end
      end
    end
    
    def check_visibility_alerts(city, data)
      # visibility check
      if data['list'] && !data['list'].empty? && data['list'].first['visibility']
        visibility = data['list'].first['visibility']
        
        if visibility < alert_rules['visibility']['fog']
          message = "Current visibility #{visibility}meters，below haze warning thresholds"
          @subscription_service.send_alert(city, message, "Haze warning!")
        end
      end
    end
    
    def alert_rules
      @alert_rules ||= begin
        YAML.load_file(File.join(File.dirname(__FILE__), '../config/alerts.yml'))
      rescue => e
        puts "⚠️ Unable to load alert rule: #{e.message}".yellow
        {
          'temperature' => { 'max' => 35.0, 'min' => 0.0 },
          'precipitation' => { 'warning' => 10.0, 'danger' => 25.0 },
          'wind' => { 'strong' => 10.8, 'storm' => 17.2 },
          'visibility' => { 'fog' => 1000 }
        }
      end
    end
  end
end
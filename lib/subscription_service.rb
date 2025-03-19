require 'yaml'
require 'mail'

module Weather
  class SubscriptionService
    def initialize
      @redis = Weather::Cache.new.instance_variable_get(:@redis)
      setup_mail_configuration
    end
    
    # Subscribe to city weather alerts
    def subscribe(email, city)
      # 
      @redis.sadd("weather:alert:#{city.downcase}", email)
      # Creating a city to mailbox mapping (used to query which cities the user is subscribed to)
      @redis.sadd("weather:user:#{email}", city.downcase)
      
      puts "✅ #{email} has successfully subscribed to weather alerts for #{city}".green
      true
    rescue Redis::BaseError => e
      puts "❌ Subscription Failure: #{e.message}".red
      false
    end
    
    # Unsubscribe from city weather alerts
    def unsubscribe(email, city)
      # Remove Bidirectional Mapping
      @redis.srem("weather:alert:#{city.downcase}", email)
      @redis.srem("weather:user:#{email}", city.downcase)
      
      puts "✅ #{email} has unsubscribed from weather alerts for  #{city}".green
      true
    rescue Redis::BaseError => e
      puts "❌ Failed to unsubscribe: #{e.message}".red
      false
    end
    
    # Get all mailboxes subscribed to the specified city
    def subscribers_for_city(city)
      @redis.smembers("weather:alert:#{city.downcase}")
    rescue Redis::BaseError => e
      puts "❌ Failed to get subscriber: #{e.message}".red
      []
    end
    
    # Get all cities subscribed by the specified mailbox
    def cities_for_user(email)
      @redis.smembers("weather:user:#{email}")
    rescue Redis::BaseError => e
      puts "❌ Failed to get subscription city: #{e.message}".red
      []
    end
    
    # Send Alert Email
    def send_alert(city, message, severity = "Alert")
      subscribers = subscribers_for_city(city)
      return if subscribers.empty?

      config = alert_config
      from_email = config.dig('notification', 'email', 'from') || 'noreply@example.com'
      
      icon = case severity
             when "Alert" then "⚠️"
             when "Danger" then "🚨"
             when "Info" then "ℹ️"
             else "📢"
             end
             
      subscribers.each do |email|
        begin
          mail = Mail.new do
            from     from_email
            to       email
            subject  "#{icon} #{city} weather warning: #{severity}"
            
            html_part do
              content_type 'text/html; charset=UTF-8'
              body <<~HTML
                <h2>#{city} weather warning</h2>
                <p><strong>Level:</strong> #{severity}</p>
                <p><strong>Details:</strong> #{message}</p>
                <p><strong>Time:</strong> #{Time.now.strftime('%Y-%m-%d %H:%M')}</p>
                <hr>
                <p>
                  <small>
                    To unsubscribe, please run:<br>
                    <code>./bin/weather unsubscribe #{email} #{city}</code>
                  </small>
                </p>
              HTML
            end
          end
          
          mail.deliver!
          puts "📧 A weather alert for #{city} has been sent to #{email}.".green
        rescue => e
          puts "❌ Email delivery failure (#{email}): #{e.message}".red
        end
      end
    end
    
    private
    
    def alert_config
      @alert_config ||= begin
        YAML.load_file(File.join(File.dirname(__FILE__), '../config/alerts.yml'))
      rescue => e
        puts "⚠️ Unable to load alert configuration: #{e.message}".yellow
        {}
      end
    end
    
    def setup_mail_configuration
        puts "=== [DEBUG] Enter setup_mail_configuration ==="
        return unless alert_config['notification'] && alert_config['notification']['email']
      
        smtp_settings = alert_config['notification']['email']['smtp']
        puts "=== [DEBUG] smtp_settings: #{smtp_settings.inspect} ==="
      
        # Make sure these settings are correct and complete
        Mail.defaults do
          delivery_method :smtp, {
            address: smtp_settings['address'],
            port: smtp_settings['port'],
            user_name: smtp_settings['user_name'],
            password: ENV['EMAIL_PASSWORD'],
            authentication: smtp_settings['authentication'],
            enable_starttls_auto: smtp_settings['enable_starttls_auto']
          }
        end
        
        # Add debug to verify settings were applied
        puts "=== [DEBUG] Mail delivery method set to: #{Mail.delivery_method.inspect} ==="
      end
  end
end
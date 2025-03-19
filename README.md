# TempestCLI

A simple powerful command-line tool for retrieving weather forecasts using the OpenWeatherMap API, with features for monitoring and alerting.

## Overview

This application allows users to quickly check weather forecasts for any city directly from the command line. It provides a clean, colorful output with relevant weather information and automatically converts timestamps to the local timezone. The app also includes an alert system that can monitor weather conditions and send email notifications when predefined thresholds are exceeded.

## Features

5-day weather forecast retrieval
Automatic local timezone conversion
Colorful, emoji-enhanced terminal output
Simple command-line interface
Secure API key management
Weather condition monitoring and alerts
Email notifications for severe weather conditions
Redis-powered caching and concurrent batch queries
Subscription management for weather alerts

## Installation

### Prerequisites

- Ruby 2.7.0 or higher
- Bundler
- Redis server (for caching and subscription management)

### Setup

1. Clone the repository:
   ```bash
   git clone repo-url
   cd project-name
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up your API key:
   - Sign up for a free API key at [OpenWeatherMap](https://openweathermap.org/api)
   - Create a `.env` file in the project root:
     ```bash
     echo "OPENWEATHER_API_KEY=your_api_key_here" > .env
     ```
   - Ensure `.env` is in your `.gitignore` file

4. Make the executable available:
   ```bash
   chmod +x bin/weather
   ```

## Usage
Basic Weather Check
Check the weather for a specific city:
```bash
bundle exec bin/weather check CITY_NAME
```

The output will display the 5-day forecast with temperature, weather conditions, and timestamps in your local timezone.

Weather Alerts
Subscribe to Alerts
Subscribe to weather alerts for a specific city:
```bash
bundle exec bin/weather subscribe USER_EMAIL CITY_NAME
```
Unsubscribe from Alerts
Unsubscribe from weather alerts for a specific city:
```bash
bundle exec bin/weather unsubscribe USER_EMAIL CITY_NAME
```
Monitor Cities
Start monitoring a city for weather conditions:
```bash
bundle exec bin/weather monitor CITY_NAME
```

Monitor All Subscribed Cities
Monitor all cities that have subscribers:
```bash
bundle exec bin/weather monitor_all
```

Test Alert System
Send a test alert to verify email configuration:
```bash
bundle exec bin/weather test_alert USER_EMAIL CITY_NAME
```

Batch Operations
The application supports concurrent batch operations for efficient processing of multiple requests:
```bash
bundle exec bin/weather batch CITY1 CITY2 CITY3 CITY4 CITY5
```
This will fetch weather data for multiple cities in parallel, utilizing Redis for efficient caching and retrieval.




## Configuration System

The application uses a flexible configuration system powered by the `dry-configurable` gem:

- **Environment-specific configuration**: Different settings for development and production
- **Configuration hierarchy**: Default values can be overridden by YAML files and environment variables
- **Centralized configuration**: All settings managed in one place

### Available Configuration Options

- `api_endpoint`: The OpenWeatherMap API endpoint URL
- `cache_ttl`: Time-to-live for cached data in seconds
- `concurrency`: Maximum number of concurrent requests
- `log_level`: Logging verbosity (debug, info, warn, error)

### Switching Environments

```bash
RACK_ENV=production ./bin/weather check London
```


## Architecture

The application follows a simple effective architecture:

- **lib/weather.rb**: Core logic for API interaction and data processing
- **bin/weather**: Command-line interface using Thor
- **config/initializers/api_keys.rb**: Secure handling of API credentials
- **lib/weather/alert_service.rb**: Monitoring and alert functionalities
- **lib/weather/subscription_service.rb**: Subscription management
- **lib/weather/cache.rb**: Redis-based caching system

### Data Flow
User Input → WeatherFetcher initialization → API request → Response handling → Formatted output
For alerts: Weather Data → Alert Service → Threshold Check → Subscription Service → Email Notification


### Key Components

- **WeatherFetcher**: Handles API requests and response processing
- **Thor CLI**: Provides a user-friendly command interface
- **Environment Variables**: Securely stores API credentials
- **SubscriptionService**: Manages user subscriptions for cities
- **Cache**: Redis-backed caching for efficient data retrieval
- **AlertService**: Monitors weather conditions and triggers alerts

## Development

### Project Structure
.
├── Gemfile
├── .env # Stores API key (not committed to git)
├── .gitignore # Includes .env
├── bin/
│ └── weather # Command-line executable
├── config/
│ └── initializers/
│ └── api_keys.rb # Loads environment variables
└── lib/
└── weather.rb # Core application logic

### Dependencies

- **httparty**: Simplified HTTP requests
- **colorize**: Terminal text coloring
- **dotenv**: Environment variable management
- **thor**: Command-line interface framework
- **rufus-scheduler**: Job scheduling for periodic weather checks
- **redis**: Redis client for caching and subscription management
- **mail**: Email sending capabilities
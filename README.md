# WeatherApp

A simple powerful command-line tool for retrieving weather forecasts using the OpenWeatherMap API.

## Overview

This application allows users to quickly check weather forecasts for any city directly from the command line. It provides a clean, colorful output with relevant weather information and automatically converts timestamps to the local timezone.

## Features

- 5-day weather forecast retrieval
- Automatic local timezone conversion
- Colorful, emoji-enhanced terminal output
- Simple command-line interface
- Secure API key management

## Installation

### Prerequisites

- Ruby 2.7.0 or higher
- Bundler

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

Check the weather for a specific city:
```bash
bundle exec bin/weather check CITY_NAME
```

The output will display the 5-day forecast with temperature, weather conditions, and timestamps in your local timezone.

## Architecture

The application follows a simple effective architecture:

- **lib/weather.rb**: Core logic for API interaction and data processing
- **bin/weather**: Command-line interface using Thor
- **config/initializers/api_keys.rb**: Secure handling of API credentials

### Data Flow
User Input → WeatherFetcher initialization → API request → Response handling → Formatted output

### Key Components

- **WeatherFetcher**: Handles API requests and response processing
- **Thor CLI**: Provides a user-friendly command interface
- **Environment Variables**: Securely stores API credentials

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

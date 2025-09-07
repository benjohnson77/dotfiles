#!/bin/bash

# Get current location using ipinfo.io
location_data=$(curl -s "https://ipinfo.io/json")
lat=$(echo "$location_data" | jq -r '.loc' | cut -d',' -f1)
lon=$(echo "$location_data" | jq -r '.loc' | cut -d',' -f2)
city=$(echo "$location_data" | jq -r '.city')
region=$(echo "$location_data" | jq -r '.region')

# Fallback coordinates (Dallas, Texas) if location detection fails
if [ "$lat" = "null" ] || [ "$lon" = "null" ] || [ -z "$lat" ] || [ -z "$lon" ]; then
    lat="32.7767"
    lon="-96.7970"
    city="Dallas"
    region="TX"
fi

# Get weather data using wttr.in (supports current location and Fahrenheit)
weather_data=$(curl -s "https://wttr.in/${lat},${lon}?format=j1&u")

# Extract current weather data
current_weather=$(echo "$weather_data" | jq -r '.current_condition[0]')
temperature_f=$(echo "$current_weather" | jq -r '.temp_F')
temperature_c=$(echo "$current_weather" | jq -r '.temp_C')
condition=$(echo "$current_weather" | jq -r '.weatherDesc[0].value')
wind_speed=$(echo "$current_weather" | jq -r '.windspeedMiles')
cloud_cover=$(echo "$current_weather" | jq -r '.cloudcover')
visibility=$(echo "$current_weather" | jq -r '.visibility')
humidity=$(echo "$current_weather" | jq -r '.humidity')

# Map weather condition to icon
icon="clear-day"  # Default
case "$condition" in
    *"Sunny"*|*"Clear"*) icon="clear-day" ;;
    *"Partly cloudy"*|*"Partly Cloudy"*) icon="partly-cloudy-day" ;;
    *"Cloudy"*|*"Overcast"*) icon="cloudy" ;;
    *"Rain"*|*"Drizzle"*|*"Shower"*) icon="rain" ;;
    *"Snow"*|*"Blizzard"*) icon="snow" ;;
    *"Thunderstorm"*|*"Thunder"*) icon="thunderstorm" ;;
    *"Fog"*|*"Mist"*) icon="fog" ;;
    *"Wind"*) icon="wind" ;;
esac

# Output results in the expected format
echo "Station Name: ${city}, ${region}"
echo "Condition: ${condition}"
echo "Icon: ${icon}"
echo "Temperature: ${temperature_f}°F"
echo "Wind Speed: ${wind_speed}"
echo "Cloud Cover: ${cloud_cover}"
echo "Visibility: ${visibility}"

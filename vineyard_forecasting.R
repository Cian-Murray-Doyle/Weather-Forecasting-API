library(readr)
library(httr)
library(rvest)
library(dplyr)
library(jsonlite)

# Read CSV file
vineyards <- read_csv("vineyards.csv")

# Read city_lat_long.csv from the URL
city_lat_long <- read_csv("city_lat_long.csv")

# Read HTML table for country codes
html_content <- read_html("https://www.iban.com/country-codes")
alpha2_code <- html_content %>%
  html_table() %>%
  .[[1]] %>%
  select(Country, `Alpha-2 code`)

# Replace country name to match other data
alpha2_code$Country <- gsub("United States of America \\(the\\)", "United States", alpha2_code$Country)

# Merge vineyards data with alpha2 codes
vineyards_alpha2 <- merge(vineyards, alpha2_code, by = "Country", all.x = TRUE)

# Merge with city latitude and longitude
vineyards_city_lat_long <- merge(vineyards_alpha2, city_lat_long, by = c("Alpha-2 code", "City"), all.x = TRUE)
vineyards_city_lat_long <- select(vineyards_city_lat_long, -`Alpha-2 code`)

# Setting up the core API for WeatherAPI
core_api <- "http://api.weatherapi.com/v1/forecast.json?"
api_key <- "759e6ee717924f80802221854232510"

# Loop through the dataframe to fetch weather forecasts
for(i in 1:nrow(vineyards_city_lat_long)) {
  q <- vineyards_city_lat_long[i, "lat,long"]
  days <- "3"
  url <- paste0(core_api, "key=", api_key, "&q=", q, "&days=", days, "&aqi=no&alerts=no")
  response <- GET(url)
  
  # Check if the response is successful and content type is JSON
  if (http_status(response)$category == "success" && grepl("application/json", headers(response)[["content-type"]])) {
    content <- content(response, "text", encoding = "UTF-8") # Specify encoding if not done automatically
    json_data <- fromJSON(content)
    
    # Check if json_data contains the expected structure
    if (!is.null(json_data$forecast) && !is.null(json_data$forecast$forecastday)) {
      vineyards_city_lat_long[i, "Today+1 Min Temp"] <- json_data$forecast$forecastday[[1]]$day$mintemp_c
      vineyards_city_lat_long[i, "Today+2 Min Temp"] <- json_data$forecast$forecastday[[2]]$day$mintemp_c
      vineyards_city_lat_long[i, "Today+3 Min Temp"] <- json_data$forecast$forecastday[[3]]$day$mintemp_c
    } else {
      warning(paste("Forecast data missing in response for row", i))
    }
  } else {
    warning(paste("Failed to get valid response for row", i))
  }
}

# Display the dataframe
print(vineyards_city_lat_long)
# 02_data_analysis.R
# Author: Mayank
# Date: July 26, 2025
# Purpose: This script performs exploratory data analysis (EDA) to understand
#          the distinct usage patterns of casual and annual Cyclistic bike
#          share riders, and generates key visualizations for reporting.

# --- 1. Load Required Libraries and Data ---
library(tidyverse) # For data manipulation (dplyr) and visualization (ggplot2)
library(lubridate) # For date and time functions, specifically 'hour()'
library(scales)    # For formatting axis labels (e.g., adding commas)

# Load the cleaned and processed data.
# Ensure the working directory is set to the project root.
df_combined <- readRDS("data/processed/df_combined_cleaned.Rds")

# --- 2. Analyze Overall Ride Durations and User Counts ---
# Calculating high-level descriptive statistics to understand fundamental
# differences in ride behavior and user volume.

# 2a: Calculate mean and median ride_length by user type
# This provides initial insight into typical ride durations for casual vs. member rides.
ride_length_summary <- df_combined %>%
  group_by(member_casual) %>%
  summarise(
    mean_ride_length_mins = mean(ride_length),
    median_ride_length_mins = median(ride_length),
    .groups = 'drop' # Drop grouping structure after summarization
  )

message("Summary of Ride Length (Minutes) by User Type:")
print(ride_length_summary)

# 2b: Count total rides by user type
# Provides the overall volume of trips for each user category.
message("\nTotal Number of Rides by User Type:")
df_combined %>% count(member_casual) %>% print()

# --- 3. Analyze Ride Patterns by Day of Week ---
# Investigating temporal usage patterns on a weekly basis to identify
# differences in routine vs. leisure-based ridership.

# 3a: Calculate ride counts by day of week for casual vs. members
# Identifies preferred riding days, revealing potential commuter vs. leisure use.
rides_by_day <- df_combined %>%
  group_by(member_casual, day_of_week) %>%
  summarise(number_of_rides = n(), .groups = 'drop')

message("\nNumber of Rides by Day of Week and User Type:")
print(rides_by_day)

# 3b: Calculate mean ride length by day of week for casual vs. members
# Validates hypotheses about ride purpose (e.g., longer rides on leisure days).
average_ride_length_by_day <- df_combined %>%
  group_by(member_casual, day_of_week) %>%
  summarise(
    mean_ride_length_mins = mean(ride_length),
    .groups = 'drop'
  )
message("\nAverage Ride Length (Minutes) by Day of Week and User Type:")
print(average_ride_length_by_day)

# --- 4. Analyze Ride Patterns by Hour of Day ---
# Drilling down into hourly usage patterns to identify specific peak times
# and reinforce behavioral distinctions between user types.

# 4a: Extract hour_of_day from 'started_at' timestamp
df_combined <- df_combined %>%
  mutate(hour_of_day = hour(started_at))

# 4b: Calculate ride counts by hour of day for casual vs. members
# Pinpoints high-demand hours, critical for operational planning and targeted marketing.
rides_by_hour <- df_combined %>%
  group_by(member_casual, hour_of_day) %>%
  summarise(
    number_of_rides = n(),
    .groups = 'drop'
  )
message("\nNumber of Rides by Hour of Day and User Type:")
# Print all rows as there are only 48 combinations (2 user types * 24 hours).
print(rides_by_hour, n = 48)

# 4c: Calculate mean ride_length by hour_of_day for casual vs. members
# Explores if ride duration characteristics vary throughout the day for each user type.
average_ride_length_by_hour <- df_combined %>%
  group_by(member_casual, hour_of_day) %>%
  summarise(
    mean_ride_length_mins = mean(ride_length),
    .groups = 'drop'
  )
message("\nAverage Ride Length (Minutes) by Hour of Day and User Type:")
print(average_ride_length_by_hour, n = 48) # Print all rows

# --- 5. Visualization Section ---
# Creating clear, professional-grade visuals to effectively communicate
# analytical findings to stakeholders.

# Ensure 'visualizations' directory exists to save plots.
if (!dir.exists("visualizations")) {
  dir.create("visualizations")
}

# 5a: Visualize Total Rides by Day of Week and Member Type
# Purpose: Illustrates the differing weekday vs. weekend usage volumes.
rides_by_day_plot <- ggplot(rides_by_day, aes(x = day_of_week, y = number_of_rides, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Total Rides by Day of Week",
    x = "Day of Week",
    y = "Number of Rides",
    fill = "User Type"
  ) +
  scale_y_continuous(labels = scales::comma) + # Format y-axis with commas for readability
  # Using 'free_y' scales because the absolute number of rides differs greatly between groups.
  # This allows the distinct patterns within each group to be clearly visible despite scale differences.
  facet_wrap(~ member_casual, scales = "free_y") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

print(rides_by_day_plot)
ggsave("visualizations/total_rides_by_day.png", plot = rides_by_day_plot, width = 10, height = 6)


# 5b: Visualize Average Ride Length by Day of Week and Member Type
# Purpose: Compares average ride durations, highlighting longer casual rides, particularly on weekends.
avg_ride_length_by_day_plot <- ggplot(average_ride_length_by_day, aes(x = day_of_week, y = mean_ride_length_mins, fill = member_casual)) +
  geom_col(position = "dodge") +
  labs(
    title = "Average Ride Length by Day of Week",
    x = "Day of Week",
    y = "Average Ride Length (Minutes)",
    fill = "User Type"
  ) +
  # Using fixed scales for the y-axis (default) to clearly show the absolute magnitude
  # of difference in average ride length between casual (longer) and member (shorter) rides.
  facet_wrap(~ member_casual) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

print(avg_ride_length_by_day_plot)
ggsave("visualizations/average_ride_length_by_day.png", plot = avg_ride_length_by_day_plot, width = 10, height = 6)


# 5c: Visualize Total Rides by Hour of Day and Member Type
# Purpose: Identifies specific hourly peaks, reinforcing commuter vs. leisure usage patterns.
rides_by_hour_plot <- ggplot(rides_by_hour, aes(x = hour_of_day, y = number_of_rides, color = member_casual)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Total Rides by Hour of Day",
    x = "Hour of Day (0-23)",
    y = "Number of Rides",
    color = "User Type"
  ) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) + # Ensure clean hourly labels
  # Using 'free_y' scales due to significant difference in total ride volume between groups,
  # allowing distinct patterns within each group to be clearly observed.
  facet_wrap(~ member_casual, ncol = 1, scales = "free_y") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

print(rides_by_hour_plot)
ggsave("visualizations/total_rides_by_hour.png", plot = rides_by_hour_plot, width = 10, height = 7)


# 5d: Visualize Average Ride Length by Hour of Day and Member Type
# Purpose: Illustrates how average ride duration changes throughout the day for each user type.
avg_ride_length_by_hour_plot <- ggplot(average_ride_length_by_hour, aes(x = hour_of_day, y = mean_ride_length_mins, color = member_casual)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Average Ride Length by Hour of Day",
    x = "Hour of Day (0-23)",
    y = "Average Ride Length (Minutes)",
    color = "User Type"
  ) +
  scale_x_continuous(breaks = seq(0, 23, by = 2)) +
  # Using 'free_y' scales to better visualize internal patterns and variations
  # in ride duration for each group, despite overall scale differences.
  facet_wrap(~ member_casual, ncol = 1, scales = "free_y") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

print(avg_ride_length_by_hour_plot)
ggsave("visualizations/average_ride_length_by_hour.png", plot = avg_ride_length_by_hour_plot, width = 10, height = 7)
# 01_data_processing.R
# Author: Mayank
# Date: July 26, 2025
# Purpose: This script performs comprehensive data cleaning, standardization,
#          and feature engineering on raw Cyclistic bike trip data from
#          2019 Q1 and 2020 Q1.
# Output: A single, clean, combined Rds file for subsequent analytical tasks.

# --- 1. Load Required Libraries ---
library(tidyverse) # For data manipulation (dplyr, tibble) and CSV reading
library(lubridate) # For date and time operations

# --- 2. Load Raw Data ---
# Loading raw quarterly trip data. Ensure 'data/raw/' directory exists
# and contains the specified CSV files.
df_2019_q1 <- read_csv("data/raw/Divvy_Trips_2019_Q1.csv")
df_2020_q1 <- read_csv("data/raw/Divvy_Trips_2020_Q1.csv")

# --- 3. Initial Data Inspection ---
# Inspecting the structure and column names of both datasets to identify
# inconsistencies prior to combining.
message("Structure of 2019 Q1 Data:")
str(df_2019_q1)
message("\nStructure of 2020 Q1 Data:")
str(df_2020_q1)

message("\nColumn names of 2019 Q1 Data:")
names(df_2019_q1)
message("Column names of 2020 Q1 Data:")
names(df_2020_q1)

# Observation: Discrepancies noted in column names (e.g., 'trip_id' vs 'ride_id')
# and 'usertype' column values ('Customer'/'Subscriber' vs 'casual'/'member').

# --- 4. Standardize 2019 Q1 Data Schema ---
# Renaming columns and standardizing categorical values in df_2019_q1 to
# align with the df_2020_q1 schema, ensuring consistent data structures for merging.
df_2019_q1 <- df_2019_q1 %>%
  rename(
    ride_id = trip_id,
    started_at = start_time,
    ended_at = end_time,
    start_station_id = from_station_id,
    end_station_id = to_station_id,
    start_station_name = from_station_name,
    end_station_name = to_station_name,
    member_casual = usertype
  ) %>%
  mutate(
    # Map old 'usertype' values ('Customer', 'Subscriber') to new 'member_casual' values.
    member_casual = case_when(
      member_casual == "Customer" ~ "casual",
      member_casual == "Subscriber" ~ "member",
      TRUE ~ member_casual
    ),
    # Convert 'ride_id' to character type for consistency across datasets.
    ride_id = as.character(ride_id)
  )

message("\nStructure of 2019 Q1 Data after Standardization:")
str(df_2019_q1)

# --- 5. Prepare 2020 Q1 Data ---
# Converting timestamp columns to datetime objects and removing redundant
# pre-calculated columns to ensure consistency with newly engineered features.
df_2020_q1 <- df_2020_q1 %>%
  mutate(
    started_at = as_datetime(started_at),
    ended_at = as_datetime(ended_at)
  ) %>%
  # Removing existing 'ride_length' and 'day_of_week' columns.
  # These will be recalculated consistently across the combined dataset.
  select(-ride_length, -day_of_week)

message("\nStructure of 2020 Q1 Data after Preparation:")
str(df_2020_q1)

# --- 6. Combine Dataframes ---
# Row-binding the two standardized dataframes into a single tibble for analysis.
message("\nCombining 2019 Q1 and 2020 Q1 data...")
df_combined <- bind_rows(df_2019_q1, df_2020_q1)

message("Glimpse of Combined Data:")
glimpse(df_combined)
message(paste("Dimensions of Combined Data:", paste(dim(df_combined), collapse = " x ")))

# --- 7. Handle Missing Values ---
# Identifying and removing rows with missing values in critical station columns.
# These columns are essential for geospatial and pattern analysis.
message("\nChecking for missing values before removal:")
colSums(is.na(df_combined))

df_combined <- df_combined %>%
  drop_na(start_station_name, end_station_name, start_station_id, end_station_id)

message("\nChecking for missing values after removal:")
colSums(is.na(df_combined))

# --- 8. Feature Engineering: Calculate Ride Length and Day of Week ---
# Creating 'ride_length' and 'day_of_week' features consistently across the
# combined dataset.
df_combined <- df_combined %>%
  # Calculate ride length in minutes.
  mutate(ride_length = as.numeric(difftime(ended_at, started_at, units = "mins"))) %>%
  # Extract day of the week, with labels (e.g., "Mon", "Tue").
  mutate(day_of_week = wday(started_at, label = TRUE))

message("\nSample of 'ride_length' column:")
df_combined %>% select(ride_length) %>% print(n = 5)

message("\nSummary statistics for 'ride_length' before outlier filtering:")
summary(df_combined$ride_length)

# --- 9. Filter Out Outliers and Invalid Rides ---
# Removing rides with non-positive duration and excessively long rides (over 24 hours).
# These are considered data entry errors or outliers that could skew analysis.
df_combined <- df_combined %>%
  filter(ride_length > 0 & ride_length <= 1440) # 1440 minutes = 24 hours

message("\nSummary statistics for 'ride_length' after outlier filtering:")
# Display summary in non-scientific notation for readability.
format(summary(df_combined$ride_length), scientific = FALSE)

message("\nGlimpse of Final Cleaned and Processed Dataframe:")
glimpse(df_combined)

# --- 10. Save Processed Data ---
# Saving the cleaned and processed dataframe to an Rds file.
# Rds format preserves data types and attributes, ensuring consistency
# when loaded for subsequent analysis.
message("\nSaving cleaned data to data/processed/df_combined_cleaned.Rds...")
saveRDS(df_combined, "data/processed/df_combined_cleaned.Rds")
message("Data processing complete and data saved successfully.")
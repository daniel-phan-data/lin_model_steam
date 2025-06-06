## copy and paste IMPORTS at the beginning of your scripts ----
# ## IMPORTS ----
# rm(list = ls()) #clean environment
# graphics.off() #clean plots
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) #set working directory
# temp_env <- new.env() #temporary environment to avoid uneccessary variables after import
# source("0setup.R", local = temp_env)
# games <- temp_env$setup()
# rm(temp_env) #delete temporary environment after data has been loaded
# 
# #select variables for analysis
# gamesc <- games %>%
#   select(Average.playtime.forever, Estimated.owners,
#          Peak.CCU, rating, Price,
#          Recommendations, Required.age,
#          Positive, Negative,
#          total_reviews, positive_ratio)

## list of packages needed ----
packages <- c(
  "tidyverse", "DataExplorer", "dplyr", "ggplot2",
  "leaps", "glmulti", "nlme", "nnet", "pscl", "car",
  "rlang", "corrplot", "ggcorrplot", "lmtest",
  "nortest"
)

## subfunctions ----
setup <- function() {
  # reset stored values
  rm(list = ls())
  # set working dir to script's location
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
  install_and_load(packages)
  games <- load_and_clean_games()
  return(games)
}

install_and_load <- function(packages) {
  # Find missing packages
  missing_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  
  # Install missing packages
  if (length(missing_packages) > 0) {
    install.packages(missing_packages, dependencies = TRUE)
  }
  
  # Load all packages
  invisible(lapply(packages, library, character.only = TRUE))
}

load_and_clean_games <- function() {
  filepath <- "../steam_data/games.csv"
  games <- read.csv(filepath)
  games <- games %>% filter(Average.playtime.forever>0 & Peak.CCU>0)
  games[is.na(games)] <- 0
  total_reviews <- games$Positive + games$Negative
  positive_ratio <- (games$Positive / total_reviews) * 100  # ratio of positive reviews
  
  # create variable total_reviews
  games <- games %>% mutate(total_reviews = mapply(create_total_reviews, Positive, Negative))
  
  # create variable positive_ratio
  games <- games %>% mutate(positive_ratio = mapply(create_positive_ratio, Positive, Negative))
  
  # create variable rating
  games <- games %>% mutate(rating = mapply(create_rating, Positive, Negative))
  # define rating category order
  rating_levels <- c("Overwhelmingly Positive", "Very Positive", "Positive", 
                     "Mostly Positive", "Mixed", 
                     "Mostly Negative", "Negative", "Very Negative", 
                     "Overwhelmingly Negative", "Not enough reviews")
  # rating as factor
  games <- games %>%
    mutate(rating = factor(rating, levels = rating_levels, ordered = TRUE))
  games <- na.omit(games)
  
  #estimated owner as factor
  games$Estimated.owners <- as.factor(games$Estimated.owners)
  games$Estimated.owners <- 
    fct_recode(games$Estimated.owners,
               "0-20k" = "0 - 20000",
               "20k-50k" = "20000 - 50000",
               "50k-100k" = "50000 - 100000",
               "100k-200k" = "100000 - 200000",
               "200k-500k" = "200000 - 500000",
               "500k-1M" = "500000 - 1000000",
               "1M-2M" = "1000000 - 2000000",
               "2M-5M" = "2000000 - 5000000",
               "5M-10M" = "5000000 - 10000000",
               "10M-20M" = "10000000 - 20000000",
               "20M-50M" = "20000000 - 50000000",
               "50M-100M" = "50000000 - 100000000",
               "100M-200M" = "100000000 - 200000000"
    )
  games$Estimated.owners <- fct_relevel(
    games$Estimated.owners,
    "0-20k", "20k-50k", "50k-100k", "100k-200k", "200k-500k", 
    "500k-1M", "1M-2M", "2M-5M", "5M-10M", "10M-20M", 
    "20M-50M", "50M-100M", "100M-200M"
  )
  return(games)
}

create_rating <- function(Positive, Negative) {
  total_reviews <- Positive + Negative
  positive_ratio <- (Positive / total_reviews) * 100  # Ratio des avis positifs
  
  if (total_reviews >= 500) {  
    if (positive_ratio >= 95 && positive_ratio <= 100) {
      return("Overwhelmingly Positive")
    } else if (positive_ratio >= 80 && positive_ratio < 95) {
      return("Very Positive")
    } else if (positive_ratio >= 70 && positive_ratio < 80) {
      return("Mostly Positive")
    } else if (positive_ratio >= 40 && positive_ratio < 70) {
      return("Mixed")
    } else if (positive_ratio >= 20 && positive_ratio < 40) {
      return("Mostly Negative")
    } else if (positive_ratio >= 0 && positive_ratio < 20) {
      return("Overwhelmingly Negative")
    }
  } 
  
  else if (total_reviews >= 50 && total_reviews <= 499) {  
    if (positive_ratio >= 80 && positive_ratio <= 100) {
      return("Very Positive")
    } else if (positive_ratio >= 70 && positive_ratio < 80) {
      return("Mostly Positive")
    } else if (positive_ratio >= 40 && positive_ratio < 70) {
      return("Mixed")
    } else if (positive_ratio >= 20 && positive_ratio < 40) {
      return("Mostly Negative")
    } else if (positive_ratio >= 0 && positive_ratio < 20) {
      return("Very Negative")
    }
  } 
  
  else if (total_reviews >= 10 && total_reviews <= 49) {  # 10-49 reviews
    if (positive_ratio >= 80 && positive_ratio <= 100) {
      return("Positive")
    } else if (positive_ratio >= 70 && positive_ratio < 80) {
      return("Mostly Positive")
    } else if (positive_ratio >= 40 && positive_ratio < 70) {
      return("Mixed")
    } else if (positive_ratio >= 20 && positive_ratio < 40) {
      return("Mostly Negative")
    } else if (positive_ratio >= 0 && positive_ratio < 20) {
      return("Negative")
    }
  } 
  
  else {
    return("Not enough reviews")  
  }
}

create_total_reviews <- function(Positive, Negative) {
  total_reviews <- Positive + Negative
  return(total_reviews)
}

create_positive_ratio <- function(Positive, Negative) {
  total_reviews <- Positive + Negative
  positive_ratio <- (Positive / total_reviews) * 100
  return(positive_ratio)
}
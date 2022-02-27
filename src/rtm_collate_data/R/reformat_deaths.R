reformat_deaths <- function(df, type_name) {
  df <- df %>%
    rename(date = dod, region = nhser_name) %>%
    mutate(type = type_name)
  
  #add England
  deaths_eng <- df %>%
    group_by(date, type) %>%
    summarise(count = sum(count, na.rm = TRUE)) %>%
    mutate(region = "England")
  
  df <- df %>% bind_rows(deaths_eng)
  
  #sort out region names
  df <- df %>%
    mutate(region = gsub(" ", "_", region))
  
  return(df)
}
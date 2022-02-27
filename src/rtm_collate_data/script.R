source("R/ltla_to_stp.R")

# Parameter from orderly.yml
date_orderly_param <- as.Date(date)

key <- cyphr::data_key()
options(dplyr.summarise.inform = FALSE)

#------ #read data}

# PHE dashboard
phe_dashboard_deaths_by_country <- readRDS("deaths_by_country.rds")
phe_healthcare <- readRDS("phe_healthcare.rds")



#---------------------------------------------------------------------------------------------------------

#---------------
# phe dashboard
phe_dashboard <-  phe_dashboard_deaths_by_country %>%
  rename(region = area_name,
         date = reporting_date,
         count = deaths) %>%
  mutate(type = "death1") %>%
  mutate(date = date) %>%
  mutate(region = gsub(" ", "_", region))

output <- phe_dashboard

# phe healthcare
phe_healthcare <- phe_healthcare %>%
  select(-c(area_code, dataset, area_type)) %>%
  rename(region = area_name) %>%
  mutate(date = date) %>%
  mutate(region = gsub(" ", "_", region))

fun_phe_hc_select <- function(phe, field, type) {
  phe2 <- phe[, c("date", "region", field)]
  names(phe2)[names(phe2) == field] <- "count"
  phe2$type <- type
  phe2
}

output <- output %>% 
  bind_rows(fun_phe_hc_select(phe_healthcare, "new_admissions", "phe_admissions"))

output <- output %>% 
  bind_rows(fun_phe_hc_select(phe_healthcare, "covid_occupied_mv_beds", "phe_occupied_mv_beds"))

output <- output %>% 
  bind_rows(fun_phe_hc_select(phe_healthcare, "hospital_cases", "phe_patients"))



#------------
#------------
#------------
#covert date to days
output <- output %>%
  filter(!is.na(date)) %>%
  arrange(date)%>%
  filter(date >  ymd("2020-03-15")) %>% 
  mutate(days_since_16_march = as.numeric(as.Date(date) - ymd("2020-03-16")))%>% 
  select(days_since_16_march, everything())

if (max(output$date) != date_orderly_param) {
  stop(sprintf("Date parameter = %s, Latest collate date = %s", date_orderly_param, max(output$date)))
}


#---------------
# make wide for rtm group
output_rtm <- output %>% 
  pivot_wider(names_from = type, values_from = count, values_fill = 0) %>%
  mutate(region = tolower(region)) %>%
  select(-days_since_16_march) %>%
  mutate(date = as.character(date)) %>%
  arrange(region, date) %>%
  filter(!is.na(region))

# check the number of rows for each
rows_out <- output_rtm %>% group_by(region) %>% summarise(rows=n()) 
if(range(rows_out$rows)[1] - range(rows_out$rows)[2] != 0){
  region_more_rows <- rows_out$region[which.max(rows_out$rows)]
  region_less_rows <- rows_out$region[which.min(rows_out$rows)]
  
  #missing dates
  dates_more <- unique(output_rtm$date[output_rtm$region == region_more_rows])
  dates_less <- unique(output_rtm$date[output_rtm$region == region_less_rows])
  
  missing_dates <- dates_more[!dates_more %in% dates_less]
  
  #add this in with NAs
  for(reg in unique(output_rtm$region)){
    tmp <-  output_rtm %>% filter(region == reg)
    for (missing_date in missing_dates) {
      if (!missing_date %in% tmp$date) {
        tmp_add <- tmp[1, ]
        tmp_add[3:ncol(tmp_add)] <- NA
        tmp_add$date <- missing_date
        output_rtm <- output_rtm %>% bind_rows(tmp_add)
      }
    }
  }
}



saveRDS(output_rtm, "uk_rtm.rds")
write.csv(output_rtm, "uk_rtm.csv", row.names = FALSE)

#---------------
# save in long
saveRDS(output, "uk_rtm_long.rds")


#---------------
# wide extract for checking
output %>%
  pivot_wider(names_from = c("region", "type"),
              values_from = count) %>%
  arrange(date) %>%
  tail() %>%
  write.csv("uk_rtm_wide_extract_for_checking.csv", row.names = FALSE)

#------------
#------------
#report

# INCLUDED FOR ILLUSTRATION BUT CANNOT RUN WITHOUT ADDITIONAL DATA

#rmarkdown::render("rtm_compare_healthcare.Rmd")
#rmarkdown::render("report.Rmd")   


## On real only, upload data to sharepoint
if (Sys.getenv("ORDERLY_API_SERVER_IDENTITY") == "dide") {
  sharepoint <- spud::sharepoint$new("https://imperiallondon.sharepoint.com")
  root <- "Shared Documents/2019-nCov/Data Collection/UK/Processed_in_R/rtm_data"
  folder <- sharepoint$folder("ncov", root, verify = TRUE)
  id <- orderly::orderly_run_info()$id
  
  root_validation <- "Shared Documents/2019-nCov/Data Collection/UK/Processed_in_R/rtm_data/validation-report"
  folder_validation <- sharepoint$folder("ncov", root_validation, verify = TRUE)
  
  #UK RTM csv
  dest2 <- sprintf("rtm_collate_%s_UK_RTM_long.csv", id)
  folder$upload("UK_RTM_long_Neil.csv", dest2)
  
  
  #save validation set if it is a thursday
  if(weekdays(Sys.Date())=="Thursday"){
    dest4 <- sprintf("rtm_collate_validation_extract_%s.csv", id)
    folder$upload("uk_rtm_wide_extract_for_checking.csv", dest4)
    
    
    dest5 <- sprintf("rtm_collate_data_%s_report.html", id)
    folder_validation$upload("report.html", dest5)
  }
}


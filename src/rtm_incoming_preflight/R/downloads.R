library(R.utils)


##############################################################################

download_phe_cases <- function(path, for_date) {
  cat("Downloading PHE Dashboard cases... ")
  
  # Filename: phe_cases_2020-Nov-09.csv
  
  
  format_date <- as.Date(for_date, format = "%Y%m%d")
  format_date <- format(format_date, "%Y-%b-%d")
  cases_file <- sprintf("phe_cases_%s.csv.gz", format_date)
  cases_file <- file.path(path, cases_file)

  url <- paste0(
    'https://api.coronavirus.data.gov.uk/v2/data?',
    'areaType=ltla&metric=cumCasesBySpecimenDate&',
    'metric=newCasesBySpecimenDate&',
    'metric=cumCasesBySpecimenDateRate&',
    'format=csv')
  
  
  download.file(url, cases_file, method = "wget", quiet = TRUE)
  
  R.utils::gunzip(cases_file, overwrite = TRUE)
  
  # Check these files contain as many dates as we expect.
  
  cases_file <- gsub("\\.gz", "", cases_file)
  
  csv_cases <- read.csv(cases_file, stringsAsFactors = FALSE)
  
  last_date <- max(csv_cases$date)
  format_date <- format(as.Date(for_date, format = "%Y%m%d"), "%Y-%m-%d")
  if (last_date != format_date) {
    cat(red(sprintf(
      "Expected last day %s, found %s\n", format_date, last_date)))
  } else {
    cat(green("OK\n"))
  }
}

##############################################################################

download_phe_deaths <- function(path, for_date) {
  cat("Downloading PHE Dashboard deaths... ")

  # Filenames we want are     data_2020-Nov-09.csv
  # and                   dod_data_2020-Nov-09.csv

  format_date <- as.Date(for_date, format = "%Y%m%d")
  format_date <- format(format_date, "%Y-%b-%d")
  dpub_file <- sprintf("data_%s.csv.gz", format_date)
  dod_file <- sprintf("dod_%s", dpub_file)
  dpub_file <- file.path(path, dpub_file)
  dod_file <- file.path(path, dod_file)

  common_link <- paste0(
    'https://api.coronavirus.data.gov.uk/v1/data?',
    'filters=areaType=overview&structure={',
    '"areaType":"areaType",',
    '"areaName":"areaName",',
    '"areaCode":"areaCode",',
    '"date":"date",')

  url <- paste0(common_link,
      '"newDeaths28DaysByPublishDate":"newDeaths28DaysByPublishDate",',
      '"cumDeaths28DaysByPublishDate":"cumDeaths28DaysByPublishDate"}',
      '&format=csv')

  download.file(url, dpub_file, method = "wget", quiet = TRUE)

  R.utils::gunzip(dpub_file, overwrite = TRUE)

  url <- paste0(common_link,
    '"newDeaths28DaysByDeathDate":"newDeaths28DaysByDeathDate",',
    '"cumDeaths28DaysByDeathDate":"cumDeaths28DaysByDeathDate"}',
    '&format=csv')

  download.file(url, dod_file, method = "wget", quiet = TRUE)

  R.utils::gunzip(dod_file, overwrite = TRUE)

  # Check these files contain as many dates as we expect.

  dod_file <- gsub("\\.gz", "", dod_file)
  dpub_file <- gsub("\\.gz", "", dpub_file)

  csv_dod <- read.csv(dod_file, stringsAsFactors = FALSE)
  csv_pub <- read.csv(dpub_file, stringsAsFactors = FALSE)

  last_date <- max(c(csv_dod$date, csv_pub$date))
  format_date <- format(as.Date(for_date, format = "%Y%m%d"), "%Y-%m-%d")
  if (last_date != format_date) {
    cat(red(sprintf(
      "Expected last day %s, found %s\n", format_date, last_date)))
  } else {
    cat(green("OK\n"))
  }
}

##############################################################################

download_phe_healthcare <- function(path, for_date) {
  cat("Downloading PHE Healthcare... ")
  format_date <- as.Date(for_date, format = "%Y%m%d")
  format_date <- format(format_date, "%Y-%b-%d")
  csv <- NULL
  for (areaType in c("nhsRegion", "nation", "overview")) {
    file <- tempfile(fileext = ".tmp.gz")
    url <- sprintf(paste0(
      "https://api.coronavirus.data.gov.uk/v2/data?",
      "areaType=%s",
      "&metric=newAdmissions",
      "&metric=covidOccupiedMVBeds",
      "&metric=hospitalCases&format=csv"), areaType)
  
    download.file(url, file, method = "wget", quiet = TRUE)
    R.utils::gunzip(file, overwrite = TRUE)

    file <- gsub("\\.gz", "", file)
    csv <- rbind(csv, read.csv(file))
  }
  
  file <- file.path(path, sprintf("phe_healthcare_%s.csv", for_date))
  write.csv(csv, file, row.names = FALSE)

  last_date <- max(as.Date(csv$date))
  format_date <- format(as.Date(for_date, format = "%Y%m%d"), "%Y-%m-%d")
  if (last_date != format_date) {
    cat(red(sprintf(
      "Expected last day %s, found %s\n", format_date, last_date)))
  } else {
    cat(green("OK\n"))
  }
}
##############################################################################

downloads <- function(path, for_date) {
  if (is.null(for_date)) {
    for_date <- format(as.Date(Sys.Date()), "%Y%m%d")
  }
 
  download_phe_cases(path, for_date)
  download_phe_deaths(path, for_date)
  download_phe_healthcare(path, for_date)

  invisible()
}

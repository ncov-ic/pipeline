check_filenames <- function(sharepoint, meta) {

  for (met in meta) {
    cat(sprintf("Checking files in %s ... ", met$path))
    files <- met$files_csv$filename
    data_root <- file.path("Shared Documents/2019-nCoV/Data collection", met$path)
    ok <- TRUE

    for (file in files) {
      meta_folder <- dirname(file)
      meta_file <- basename(file)
      sp_folder <- sharepoint$folder("ncov", file.path(data_root, meta_folder), verify = TRUE)
      sp_files <- sp_folder$files()

      if (!meta_file %in% sp_files$name) {
        ok <- FALSE
        cat(red(sprintf("%s NOT FOUND\n", meta_file)))
      }
    }
    if (ok) {
      cat(green("OK\n"))
    }
  }
}

days_ago <- function(d, date) {
  if (is.null(date)) {
    d2 = Sys.Date()
  } else {
    d2 = as.Date(date, format = "%Y%m%d")
  }
  as.integer(as.Date(d) - d2)
}

test_daily_no_weekend <- function(dd, id, date) {
  cat(sprintf("Checking dates for %s ... ", id))
  ago <- days_ago(as.Date(dd[1]), date)
  day <- format(Sys.Date(), "%a")
  if (ago > 0) {
    cat(red("future date\n"))

  } else if (ago == 0) {
    cat(green("OK\n"))

  } else if ((ago == -1) && (day == "Sat")) {
    cat(blue("1 day behind (but it's Saturday)\n"))

  } else if ((ago == -1) && (day == "Sun")) {
    cat(blue("1 day behind (but it's Sunday)\n"))

  } else if ((ago == -2) && (day == "Sun")) {
    cat(blue("2 days behind (but it's Sunday)\n"))

  } else if (ago == -1) {
    cat(red(sprintf("last updated %d day ago\n", -ago)))

  } else {
    cat(red(sprintf("last updated %d days ago\n", -ago)))
  }
}

test_daily <- function(dd, id, date) {
  cat(sprintf("Checking dates for %s ... ", id))
  ago <- days_ago(dd[1], date)
  if (ago == -1) {
    cat(red("last updated 1 day ago\n"))
  } else if (ago < -1) {
    cat(red(sprintf("last updated %d days ago\n", -ago)))
  } else if (ago > 0) {
    cat(red("future date\n"))
  } else {
    cat(green("OK\n"))
  }
}

test_dual_dates_no_weekend <- function(dd, id, date) {
  if (dd[1] != dd[2]) {
    cat(sprintf("Checking dates for %s ... ", id))
    cat(red("Mismatched dates"))
  } else {
    test_daily_no_weekend(dd[1], id, date)
  }
}


test_weekly <- function(d, id, date) {
  cat(sprintf("Checking dates for %s ... ", id))
  ago <- days_ago(d, date)
  if (ago <= -7) {
    cat(red(sprintf("last updated %d days ago\n", -ago)))
  } else {
    cat(green("OK\n"))
  }
}

test_phe_dashboard_dates <- function(met, date) {
  test_daily(met$date[met$type == "newdeaths"], "PHE Dashboard deaths", date)
  test_daily(met$date[met$type == "newdeathsbydod"], "PHE Dashboard deaths by date of death", date)
  test_daily(met$date[met$type == "cases"], "PHE Dashboard cases", date)
  test_daily(met$date[met$type == "healthcare"], "PHE Dashboard Healthcare", date)
}



check_up_to_date <- function(meta, date) {
  test_phe_dashboard_dates(meta$PHE_Dashboard$files_csv, date)
}

get_all_meta <- function(sharepoint) {

  get_single_meta <- function(sharepoint, path) {
    root <- file.path("Shared Documents/2019-nCoV/Data collection", path)
    folder <- sharepoint$folder("ncov", root, verify = TRUE)
    list(path = path,
         files_csv = readxl::read_excel(folder$download("files.xlsx")))
  }

  list(
    PHE_Dashboard = get_single_meta(sharepoint, "UK/PHE Dashboard")
  )
}

checks <- function(date = NULL) {
  if (is.null(date)) {
    date <- format(Sys.Date(), "%Y%m%d")
  }
  key <- cyphr::data_key()
  sharepoint <- spud::sharepoint$new("https://imperiallondon.sharepoint.com")
  meta <- get_all_meta(sharepoint)
  check_filenames(sharepoint, meta)
  check_up_to_date(meta, date)
}


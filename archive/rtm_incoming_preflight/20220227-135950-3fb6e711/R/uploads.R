library(crayon)
library(spud)
library(openxlsx)
library(dplyr)

# So. If I've downloaded all the files into a folder, scripts in here will
# them all in the right place on the Sharepoint, compressing CSVs if we
# want that.

upload_file <- function(file, rootf, subf, for_date, meta,
                        move_uploaded_to = NULL) {

  move_file <- function(from_file, to_dir) {
    if (!file.exists(to_dir)) {
      dir.create(to_dir, recursive = TRUE)
    }
    file.rename(from = from_file, to = file.path(to_dir, basename(from_file)))
  }

  root <- file.path("Shared Documents/2019-nCoV/Data collection", rootf)
  sharepoint <- spud::sharepoint$new("https://imperiallondon.sharepoint.com")
  rootfolder <- sharepoint$folder("ncov", root, verify = TRUE)

  # Create any directories (one layer at a time)
  # Create is silent if a folder already exists.

  bits <- unlist(strsplit(subf, "/"))
  newfolder <- ""
  for (bit in bits) {
    newfolder <- file.path(newfolder, bit)
    if (substr(newfolder, 1, 1) == "/") {
      newfolder <- substring(newfolder, 2)
    }

    rootfolder$create(newfolder)
  }

  datafolder <- sharepoint$folder(
    "ncov", file.path("Shared Documents/2019-nCoV/Data collection", rootf,
                      newfolder), verify = TRUE)

  ########################################################################
  # If the file needs some processing (eg. compression) before upload...

  if (meta$ftype %in% c("do_unzip", "wales_lim_zip")) {
    cat(blue("UNZIP -> \n"))
    new_file <- zip::zip_list(file)$filename[1]
    zip::unzip(file, overwrite = TRUE, exdir = dirname(file))
    file.remove(file)
    return()
  }

  if (meta$ftype %in% c("wales_lims_csv", "single_unzipped",
                        "2coltype_unzipped")) {
    cat(cyan("XZ -> "))
    gzip(filename = file, overwrite = TRUE, ext = "xz", FUN = xzfile,
         compression = -5)
    file <- sprintf("%s.xz", file)
    meta$ftype <- gsub("_unzipped", "", meta$ftype)
    meta$ftype <- gsub("_csv", "", meta$ftype)
  }

  ########################################################################

  datafolder$upload(file)
  if (!is.null(move_uploaded_to)) {
    move_file(file, move_uploaded_to)
  }

  # Now we (probably) need to update files.xlsx

  if (meta$ftype == "none") {
    # Just a copy - no updating needed.
    cat(green("DONE "))
    cat(silver("files.xlsx update not needed\n"))
    return()
  }

  file_string <- file.path(subf, basename(file))
  fx <- tempfile(fileext = ".xlsx")
  rootfolder$download("files.xlsx", dest = fx)
  options("openxlsx.dateFormat" = "mm/dd/yyyy")
  workbook <- openxlsx::loadWorkbook(fx)
  sheet <- workbook$sheet_names[1]

  data <- openxlsx::read.xlsx(workbook, detectDates = TRUE)
  the_date <- as.Date(paste(substring(for_date, 1, 4),
                      substring(for_date, 5, 6),
                      substring(for_date, 7, 8), sep = "-"),
                      format = "%Y-%m-%d")


  ##########################################################################
  # Files with a single entry (MHLDA, Deaths, Sweden...)
  # Update col 1 with date and col 2 with file

  if (meta$ftype == "single") {
    data$date <- the_date
    data$filename <- file_string
    openxlsx::writeData(workbook, sheet, startCol = 1, startRow = 1,
                        data)

  ##########################################################################
  # Files where we update 2 columns, but also have a type column
  # to match with meta$fval.

  } else if (meta$ftype == "2coltype") {
    type_cols <- c("type", "deaths_ICU")
    type_col <- type_cols[which(type_cols %in% names(data))]
    data$date[data[[type_col]] == meta$fval] <- the_date
    data$filename[data[[type_col]] == meta$fval] <- file_string
    
  ##########################################################################

      # Files where we append, but have a type column.
    
  } else if (meta$ftype == "2coltype_append") {
    new_bit <- data.frame(stringsAsFactors = FALSE,
                          date = the_date,
                          filename = file_string,
                          type = meta$fval,
                          Notes = "")
    names(new_bit)[3] <- names(data)[3]
    data <- rbind(data, new_bit)
    
  ##########################################################################
  # Covid-sitrep special case.
  # Copy last line,

  } else if (meta$ftype == "covid_sitrep") {

    if (the_date %in% unique(data$date)) {
      cat(yellow(sprintf("Date %s already found in Covid Sitrep files.xlxs\n", the_date)))
      return()
    } else {
      data <- rbind(data, data.frame(stringsAsFactors = FALSE,
       date = the_date,
       filename = file_string,
       last_date_of_data = the_date,
       cleaning_function = data$cleaning_function[nrow(data)],
       type = "", notes = NA))
    }
 
  ##########################################################################
  # Vacc booster - append to NHS-Vaccination.
  #
    
  } else if (meta$ftype == "vacc_booster") {
    
    if (the_date %in% unique(data$date[data$type == 'booster'])) {
      cat(yellow(sprintf("Date %s already found for boosters in NHS-Vaccination files.xlxs\n", the_date)))
      return()
    } else {
      data <- rbind(data, data.frame(stringsAsFactors = FALSE,
                                     date = the_date,
                                     filename = file_string,
                                     type = "booster",
                                     Notes = NA))
    }
    

  ##########################################################################
  # wales_sitrep special case
  # Add a line with date, file and "daily"
  # as long as that date doesn't already exist for a "daily" entry.

  } else if (meta$ftype == "wales_sitrep") {
    if (the_date %in% unique(data$date[data$type == 'daily'])) {
      cat(yellow(sprintf("Date %s already found in NHS_Wales files.xlxs\n", the_date)))
      return()
    } else {
      data <- rbind(data, data.frame(stringsAsFactors = FALSE,
                                     date = the_date,
                                     filename = file_string,
                                     type = "daily",
                                     Notes = ""))
    }

  ##########################################################################
  # wales_lims special case. Append date and file if it doesn't
  # exist already

  } else if (meta$ftype == "wales_lims") {

    if (the_date %in% unique(data$date)) {
      cat(yellow(sprintf("Date %s already found in Wales-LIMS files.xlxs\n", the_date)))
      return()
    } else {

      data <- rbind(data, data.frame(stringsAsFactors = FALSE,
                                     date = the_date,
                                     filename = file_string,
                                     Notes = ""))
    }

  ##########################################################################
  # ONS deaths for Scotland - this is a replacement of
  # the single row with nation = 'Scotland'

  } else if (meta$ftype == "ons_scot") {
    row <- which(data$nation %in% 'Scotland')
    data$date[row] <- the_date
    data$filename[row] <- file_string

  ##########################################################################
  # ONS deaths for NI or England Wales are similar.
  # An append would do - but let's keep it tidy. Insert after the last
  # other entry for that nation - if the date/file is not already included.

  } else if (meta$ftype %in% c("ons_ni", "ons_engwales")) {
    nation <- "Northern Ireland"
    if (meta$ftype == "ons_engwales") {
      nation <- "England and Wales"
    }

    data_nation <- split(data, data$nation)
    nation_list <- unlist(lapply(data_nation, function(x) x$nation[1]))
    nation_no <- as.integer(which(nation == nation_list))
    notes <- data_nation[[nation_no]]$notes[nrow(data_nation[[nation_no]])]

    data_nation[[nation_no]] <- rbind(data_nation[[nation_no]],
      data.frame(stringsAsFactors = FALSE,
                 date = the_date,
                 filename = file_string,
                 nation = nation,
                 notes = notes))

    data <- dplyr::bind_rows(data_nation)
  }

  #######################################################################
  # Done - save workbook!

  openxlsx::writeData(workbook, sheet, startCol = 1, startRow = 1, data)
  openxlsx::saveWorkbook(workbook, fx, overwrite = TRUE)
  rootfolder$upload(fx, dest = "files.xlsx", )
  cat(green("DONE\n"))
}

#########################################################################

uploads <- function(path, for_date = NULL, move_uploaded_to = NULL) {
  if (is.null(for_date)) {
    for_date <- format(Sys.time(), "%Y%m%d")
  }
  stopifnot(nchar(for_date) == 8)
  m3 <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug",
          "Sep", "Oct", "Nov", "Dec")
  
  mall <- c("January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December")



  gsub_date <- function(x, year, short_year, month, day, ch_month,
                        chall_month) {
    x <- gsub(":Y", year, x)
    x <- gsub(":y", short_year, x)
    x <- gsub(":M", month, x)
    x <- gsub(":D", day, x)
    x <- gsub(":B", chall_month, x)
    gsub(":m", ch_month, x)
  }

  # Expected date format YYYYMMDD

  year <- substr(for_date, 1, 4)
  month <- substr(for_date, 5, 6)
  day <- substr(for_date, 7, 8)
  short_year <- substr(for_date, 3, 4)
  ch_month <-  m3[as.integer(month)]
  chall_month <- mall[as.integer(month)]

  # Dictionary of how to spot/process files...
 
  dict <- read.csv("incoming_files.csv")

  for (i in seq_len(nrow(dict))) {
    regex <- dict$regex[i]
    regex <- gsub_date(regex, year, short_year, month, day, ch_month,
                       chall_month)

    func <- dict$type[i]
    files <- list.files(path)
    res <- which(grepl(regex, files))

    if (length(res) > 1) {
      cat(blue(sprintf("Warning - ambiguous matches for %s\n", func)))

    } else if (length(res) == 1) {
      cat(black(sprintf("Uploading %s ... ", func)))
      rootfolder <- dict$rootfolder[i]
      subfolder <- dict$datasubfolder[i]
      subfolder <- gsub_date(subfolder, year, short_year, month, day, ch_month,
                             chall_month)
      upload_file(file.path(path, files[res]), rootfolder, subfolder, for_date,
                  dict[i, ], move_uploaded_to)

    }
  }
}

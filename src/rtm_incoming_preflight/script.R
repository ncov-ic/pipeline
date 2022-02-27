#drat:::add("ncov-ic")
#install.packages("spud")
#install.packages("fstorr")

source("R/download.R")
source("R/download_dhsc.R")
source("R/downloads.R")
source("R/uploads.R")
source("R/checks.R")

rmarkdown::render("rtm_incoming_preflight.Rmd")


path_to_use <- "E:/Stuff"
date_to_use <- "20220227"

downloads(path = path_to_use, for_date = date_to_use)

uploads(path = path_to_use, for_date = date_to_use,
        move_uploaded_to = paste0(path_to_use,"/Backup"))




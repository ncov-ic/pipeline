#drat:::add("ncov-ic")
#install.packages("spud")
#install.packages("fstorr")
rmarkdown::render("rtm_incoming_preflight.Rmd")


path_to_use <- "~/DATA"
date_to_use <- "20220227"

downloads(path = path_to_use, for_date = date_to_use)

uploads(path = path_to_use, for_date = date_to_use,
        move_uploaded_to = paste0(path_to_use,"/Backup"))




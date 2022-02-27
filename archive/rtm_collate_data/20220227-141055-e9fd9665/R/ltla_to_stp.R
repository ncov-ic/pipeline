##############################################################################
# LTLA to STP lookup, using proportions of LSOA in each STP where there are
# splits.

do_ltla_to_stp <- function(d, LTLA_FIELD = "ltla_code", STPCD_FIELD = "stp_code",
                              STPNM_FIELD = "stp_name", single_stp = TRUE) {

  # Filter out NA LTLA

  d_na_ltlas <- d[is.na(d[[LTLA_FIELD]]), ]
  if (nrow(d_na_ltlas) > 0) {
    if (!is.null(STPCD_FIELD)) d_na_ltlas[[STPCD_FIELD]] <- NA
    if (!is.null(STPNM_FIELD)) d_na_ltlas[[STPNM_FIELD]] <- NA
  }
  
  ltla_stp_props <- read.csv("ltla_stp_props.csv", stringsAsFactors = FALSE)
  dup_ltlas <- names(which(table(ltla_stp_props$LAD19CD) > 1))
  ltla_stp_props_singles <- ltla_stp_props[!ltla_stp_props$LAD19CD %in% dup_ltlas, ]
  ltla_stp_props_dups <- ltla_stp_props[ltla_stp_props$LAD19CD %in% dup_ltlas, ]

  # Single STPs are easy...

  singles <- d[d[[LTLA_FIELD]] %in% ltla_stp_props_singles$LAD19CD, ]
  match_singles <- match(singles[[LTLA_FIELD]], ltla_stp_props$LAD19CD)
  singles[[STPCD_FIELD]] <- ltla_stp_props$STP19CD[match_singles]
  if (!is.null(STPNM_FIELD)) {
    singles[[STPNM_FIELD]] <- ltla_stp_props$STP19NM[match_singles]
  }

  # For the dups... currently a choice of two STPs for each.

  dups <- d[d[[LTLA_FIELD]] %in% ltla_stp_props_dups$LAD19CD, ]
  dups[[STPCD_FIELD]] <- NA

  # For each LTLA we want to split
  for (ltla in unique(dups[[LTLA_FIELD]])) {

    # Get the STPs we want to split or choose between. 
    
    stp1 <- ltla_stp_props$STP19CD[ltla_stp_props$LAD19CD == ltla][1]
    stp2 <- ltla_stp_props$STP19CD[ltla_stp_props$LAD19CD == ltla][2]
    prop1 <- ltla_stp_props$prop[ltla_stp_props$LAD19CD == ltla][1]
    which_rows <- which(dups[[LTLA_FIELD]] == ltla)
    
    if (single_stp) {
      dups[[STPCD_FIELD]][which_rows] <- ifelse(prop1 >= 0.5, stp1, stp2)

    } else {
      
      allocate <- rep(0, length(which_rows))
      
      # Allocate first row to first entry (to avoid div zero)
      
      count_stp1 <- 1
      count_stp2 <- 0
      
      # For the other rows, allocate one by one, targeting
      # the proportion we want.

      for (j in 2:length(which_rows)) {
        if (count_stp1 / (count_stp1 + count_stp2) <= prop1) {
          count_stp1 <- count_stp1 + 1
        } else {
          count_stp2 <- count_stp2 + 1
          allocate[j] <- 1
        }
      }
      
      dups[[STPCD_FIELD]][which_rows[allocate == 0]] <- stp1
      dups[[STPCD_FIELD]][which_rows[allocate == 1]] <- stp2
    }
  }
  
  if (!is.null(STPNM_FIELD)) {
    dups[[STPNM_FIELD]] <- ltla_stp_props$STP19NM[
      match(dups[[STPCD_FIELD]], ltla_stp_props$STP19CD)]
  }

  rbind(singles, dups, d_na_ltlas)

}

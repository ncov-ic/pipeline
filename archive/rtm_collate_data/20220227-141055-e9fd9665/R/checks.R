check_death2 <- function(df){
  ind <- grep("death2", names(df))
  for(i in ind){
    stopifnot(!all(is.na(df[,i])))
  }
}

set_NA <- function(df){
  for(i in 2:ncol(df)){
    if(sum(df[,i], na.rm = TRUE)>0){
      df[which(is.na(df[, i])), i] <- 0
    }
  }
  return(df)
}

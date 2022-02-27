rename_variable_short <- function(df){
  
  var_names <- read.csv("data-files/var_names.csv", stringsAsFactors = FALSE)
  
  df$type2 <- var_names$nice_name[match( df$type, var_names$var_name)]
  
 
  return(df)
}


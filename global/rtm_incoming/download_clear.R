## NOTE: This version does *not* encrypt files
version_check <- function(name, version) {
  fmt <- "Please update %s with: drat:::add('ncov-ic'); install.packages('%s')"
  if (packageVersion(name) < version) {
    stop(sprintf(fmt, name, name))
  }
}
version_check("spud", "0.1.1")
version_check("fstorr", "0.1.0")


get_resource <- function(filename, folder) {
  message(sprintf("Downloading %s...", filename), appendLF = FALSE)
  ret <- folder$download(filename, raw())
  message(crayon::green("OK"))
  ret
}


hash_content <- function(data) {
  as.character(openssl::sha256(data))
}


file_cache <- function(name, folder) {
  root <- rprojroot::find_root(rprojroot::is_git_root)
  path <- file.path(root, "cache", name)
  if (file.exists(path) && !file.exists(file.path(path, "data"))) {
    stop("Please remove previous cache version")
  }
  fstorr::fstorr(
    path,
    purrr::partial(get_resource, folder = folder),
    hash_content)
}


download_files <- function(path, task, filter_type = NULL) {
  root <- file.path("Shared Documents/2019-nCoV/Data collection", path)
  sharepoint <- spud::sharepoint$new("https://imperiallondon.sharepoint.com")

  folder <- sharepoint$folder("ncov", root, verify = TRUE)

  meta <- folder$download("files.xlsx")
  files <- readxl::read_excel(meta)
  if (!is.null(filter_type)) {
    files <- files[files$type %in% filter_type, ]
  }
  files$date <- as.Date(files$date)

  obj <- file_cache(task, folder)
  filename_full <- obj$get(files$filename)
  files$sha256 <- obj$hash(files$filename)

  ## Write out file metadata:
  write.csv(files, "files.csv", row.names = FALSE)

  files$filename_clean <- filename_full

  invisible(files)
}

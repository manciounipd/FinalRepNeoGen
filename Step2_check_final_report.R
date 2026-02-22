BASE_DIR <- "/mnt/user_data/enrico/Genotipi/Neogen100k/Scarichi"
setwd(BASE_DIR)

dirs <- list.files()

check_final_report <- function(path_folder) {
  all_candidates <- list.files(
    path_folder,
    pattern = "FinalReport",
    full.names = TRUE,
    ignore.case = TRUE
  )

  files_only <- all_candidates[!dir.exists(all_candidates)]
  txt_files <- files_only[grepl("\\.txt$", files_only, ignore.case = TRUE)]
  zip_files <- files_only[grepl("\\.zip$", files_only, ignore.case = TRUE)]

  if (length(txt_files) > 1) {
    return(list(
      status = "ERROR_MULTIPLE_TXT",
      final_report = paste(txt_files, collapse = ";"),
      zip_found = length(zip_files),
      action = "none"
    ))
  }

  if (length(txt_files) == 1) {
    return(list(
      status = "OK_TXT_PRESENT",
      final_report = txt_files[1],
      zip_found = length(zip_files),
      action = "none"
    ))
  }

  if (length(zip_files) > 1) {
    return(list(
      status = "ERROR_MULTIPLE_ZIP",
      final_report = NA_character_,
      zip_found = length(zip_files),
      action = "none"
    ))
  }

  if (length(zip_files) == 1) {
    unzip(zip_files[1], exdir = path_folder, overwrite = TRUE)

    post_candidates <- list.files(
      path_folder,
      pattern = "FinalReport",
      full.names = TRUE,
      ignore.case = TRUE
    )
    post_files <- post_candidates[!dir.exists(post_candidates)]
    post_txt <- post_files[grepl("\\.txt$", post_files, ignore.case = TRUE)]

    if (length(post_txt) == 1) {
      return(list(
        status = "OK_EXTRACTED",
        final_report = post_txt[1],
        zip_found = 1L,
        action = "unzipped"
      ))
    }

    if (length(post_txt) > 1) {
      return(list(
        status = "ERROR_MULTIPLE_TXT_AFTER_UNZIP",
        final_report = paste(post_txt, collapse = ";"),
        zip_found = 1L,
        action = "unzipped"
      ))
    }

    return(list(
      status = "ERROR_NO_TXT_AFTER_UNZIP",
      final_report = NA_character_,
      zip_found = 1L,
      action = "unzipped"
    ))
  }

  return(list(
    status = "MISSING_FINALREPORT",
    final_report = NA_character_,
    zip_found = 0L,
    action = "none"
  ))
}

find_map_file <- function(path_folder) {
  map_candidates <- list.files(
    path_folder,
    pattern = "SNP[_ ]*Map.*\\.(txt|zip)$",
    full.names = TRUE,
    ignore.case = TRUE
  )
  map_files <- map_candidates[!dir.exists(map_candidates)]

  if (length(map_files) == 0) return(NA_character_)
  if (length(map_files) == 1) return(map_files[1])

  txt_map <- map_files[grepl("\\.txt$", map_files, ignore.case = TRUE)]
  if (length(txt_map) >= 1) return(txt_map[1])

  map_files[1]
}

out <- data.frame(
  folder = character(),
  status = character(),
  final_report = character(),
  map_file = character(),
  zip_found = integer(),
  action = character(),
  stringsAsFactors = FALSE
)

for (d in dirs) {
  folder_path <- file.path(BASE_DIR, d)
  if (!dir.exists(folder_path)) next

  message("Checking folder: ", d)
  res <- check_final_report(folder_path)
  map_file <- find_map_file(folder_path)

  out <- rbind(
    out,
    data.frame(
      folder = d,
      status = res$status,
      final_report = res$final_report,
      map_file = map_file,
      zip_found = as.integer(res$zip_found),
      action = res$action,
      stringsAsFactors = FALSE
    )
  )
}


qunado=as.Date(Sys.Date() ,format='%m/%d/%Y')

data.table::fwrite(out, paste0("../resume_finalreport_info",qunado,".csv"))
data.table::fwrite(out, paste0("../resume_finalreport_info.csv"))

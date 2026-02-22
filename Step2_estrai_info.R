BASE_DIR <- "/mnt/user_data/enrico/Genotipi/Neogen100k/Scarichi"
setwd(BASE_DIR)

dirs <- list.files()

resolve_final_report <- function(ped_dir, ctx = "") {
  candidates <- list.files(
    ped_dir,
    pattern = "FinalReport",
    full.names = TRUE,
    ignore.case = TRUE
  )
  files_only <- candidates[!dir.exists(candidates)]

  non_zip <- files_only[!grepl("\\.zip$", files_only, ignore.case = TRUE)]
  zip_only <- files_only[grepl("\\.zip$", files_only, ignore.case = TRUE)]

  if (length(non_zip) > 1) {
    stop("Trovati piu FinalReport non-zip in ", ctx, " (", ped_dir, ")")
  }
  if (length(zip_only) > 1) {
    stop("Trovati piu FinalReport.zip in ", ctx, " (", ped_dir, ")")
  }

  # Se c'e gia un FinalReport non-zip valido, usa quello anche se c'e anche lo zip.
  if (length(non_zip) == 1) {
    return(non_zip)
  }

  # Se non c'e non-zip ma c'e un solo zip, estrai e cerca di nuovo.
  if (length(zip_only) == 1 && length(non_zip) == 0) {
    system(sprintf("unzip -o %s -d %s", shQuote(zip_only), shQuote(ped_dir)))

    candidates2 <- list.files(
      ped_dir,
      pattern = "FinalReport",
      full.names = TRUE,
      ignore.case = TRUE
    )
    files_only2 <- candidates2[!dir.exists(candidates2)]
    non_zip2 <- files_only2[!grepl("\\.zip$", files_only2, ignore.case = TRUE)]

    if (length(non_zip2) > 1) {
      stop("Dopo unzip trovati piu FinalReport non-zip in ", ctx, " (", ped_dir, ")")
    }
    if (length(non_zip2) == 1) {
      return(non_zip2)
    }

    return(zip_only)
  }

  return(NA_character_)
}

all <- data.frame(
  folder = character(),
  ped_file = character(),
  final_report = character(),
  n_animals = integer(),
  stringsAsFactors = FALSE
)

for (i in seq_along(dirs)) {
  message("Processing folder: ", dirs[i])
  setwd(dirs[i])

  zips <- list.files(".", pattern = "^PLINK.*\\.zip$", full.names = TRUE)
  plink_files <- system("ls PLINK*/*.ped 2>/dev/null", intern = TRUE)

  if (length(zips) > 0 && length(plink_files) == 0) {
    for (z in zips) {
      system(sprintf("unzip -o %s", shQuote(z)))
    }
    plink_files <- system("ls PLINK*/*.ped 2>/dev/null", intern = TRUE)
  }

  if (length(plink_files) > 0) {
    clean_idx <- grep("clean", plink_files)
    if (length(clean_idx) > 0) {
      P <- plink_files[-clean_idx]
    } else {
      P <- plink_files
    }
  } else {
    P <- "Missing"
  }

  if (length(P) == 1 && P == "Missing") {
    stop("Manca file PED in folder: ", dirs[i])
  } else {
    final_reports <- rep(NA_character_, length(P))
    n_animals <- rep(NA_integer_, length(P))

    for (k in seq_along(P)) {
      ped_path <- P[k]
      ped_dir <- dirname(ped_path)

      final_reports[k] <- resolve_final_report(
        ped_dir = ped_dir,
        ctx = paste0("folder=", dirs[i], ", ped=", ped_path)
      )
      if (is.na(final_reports[k])) {
        stop("Manca FinalReport per PED: ", ped_path, " (folder=", dirs[i], ")")
      }

      if (!is.na(final_reports[k]) && grepl("\\.txt$", final_reports[k], ignore.case = TRUE)) {
        n_lines <- suppressWarnings(
          as.integer(system(sprintf("wc -l < %s", shQuote(final_reports[k])), intern = TRUE))
        )
        if (!is.na(n_lines)) {
          n_animals[k] <- max(0L, n_lines - 1L)
        }
      }

      if (is.na(n_animals[k])) {
        n_animals[k] <- suppressWarnings(
          as.integer(system(sprintf("wc -l < %s", shQuote(ped_path)), intern = TRUE))
        )
      }
    }

    all <- rbind(
      all,
      data.frame(
        folder = dirs[i],
        ped_file = P,
        final_report = final_reports,
        n_animals = n_animals,
        stringsAsFactors = FALSE
      )
    )
  }

  setwd("..")
}

print(all)

parts <- data.frame(
  main_dir = all$folder,
  PLINK_dir = NA_character_,
  file_types = NA_character_,
  final_report = all$final_report,
  n_animals = all$n_animals,
  stringsAsFactors = FALSE
)

split_ped <- strsplit(all$ped_file, "/", fixed = TRUE)
is_ped <- all$ped_file != "Missing" & lengths(split_ped) >= 2

parts$PLINK_dir[is_ped] <- vapply(split_ped[is_ped], `[`, character(1), 1)
parts$file_types[is_ped] <- vapply(split_ped[is_ped], `[`, character(1), 2)
parts$file_types <- gsub("\\.ped$", "", parts$file_types, ignore.case = TRUE)

data.table::fwrite(x = parts, file = "../resume_plink_info.csv")

#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readxl)
  library(data.table)
})

args <- commandArgs(trailingOnly = TRUE)
ids_file <- if (length(args) >= 1) args[1] else "/mnt/user_data/enrico/Genotipi/Neogen100k/ids.txt"
xlsx_file <- if (length(args) >= 2) args[2] else "/mnt/user_data/enrico/Genotipi/Neogen100k/file_addizionali/Matricole_valdo_PNRR_UNIMI.xlsx"
out_file <- if (length(args) >= 3) args[3] else "ids_matricole_merged.tsv"
id_col_raw <- if (length(args) >= 4) args[4] else "Marticola"


xlsx <- NULL
join_col <- NULL
id_col_idx <- suppressWarnings(as.integer(id_col_raw))

xlsx <- as.data.table(read_excel(xlsx_file))
  
ids <- fread(ids_file, header = FALSE, col.names = "Matricola", data.table = TRUE)

merged <- xlsx[ids, on = "Matricola"]

fwrite(merged, "/mnt/user_data/enrico/Genotipi/Neogen100k/ids_matricole_merged.tsv", sep = "\t", quote = FALSE, na = "NA")

message("Wrote: ", out_file)

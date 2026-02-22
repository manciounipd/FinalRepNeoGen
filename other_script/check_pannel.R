#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(data.table)
  library(tools)
})




bims <- list.files(".", pattern = "\\.bim$", full.names = TRUE)
missnp_f <- if (length(args) >= 2) args[2] else NA_character_

if (length(bims) == 0) stop("Nessun .bim trovato in: ", bim_dir)

read_bim <- function(f) {
  # BIM: CHR SNP CM BP A1 A2
  dt <- fread(f, header = FALSE, sep = "\t", data.table = TRUE, showProgress = FALSE)
  if (ncol(dt) < 6) stop("Formato .bim inatteso per: ", f)
  setnames(dt, 1:6, c("CHR","SNP","CM","BP","A1","A2"))
  dt[, file := basename(f)]
  dt[]
}


# summary per file
summ <- rbindlist(lapply(bims, function(f) {
  dt <- read_bim(f)
  data.table(
    file = unique(dt$file),
    n_snps = nrow(dt),
    allele0 = sum(dt$A1 == "0" | dt$A2 == "0"),
    chr0    = sum(dt$CHR == 0),
    dup_id  = sum(duplicated(dt$SNP)),
    indel   = sum(dt$A1 %in% c("I","D") | dt$A2 %in% c("I","D"))
  )
}))

setorder(summ, -allele0, -chr0, -dup_id)
print(summ)

if (!is.na(missnp_f) && file.exists(missnp_f)) {
  miss <- fread(missnp_f, header = FALSE)[[1]]
  cat("\n--- Analisi su missnp:", missnp_f, " (n=", length(miss), ")\n", sep="")

  # carica solo colonne necessarie e filtra ai missnp per velocità
  miss_res <- rbindlist(lapply(bims, function(f) {
    dt <- read_bim(f)
    dt <- dt[SNP %in% miss, .(file, SNP, A1, A2)]
    dt[, allele0 := (A1=="0" | A2=="0")]
    dt
  }))

  # quanti missnp con allele0 per file
  miss_summ <- miss_res[, .(
    n_missnp_present = .N,
    missnp_with_allele0 = sum(allele0)
  ), by = file][order(-missnp_with_allele0, -n_missnp_present)]
  print(miss_summ)

  # per i primi 10 SNP problematici: mostra alleli per-file (wide)
  top_snps <- miss_res[, .N, by=SNP][order(-N)][1:min(10, .N), SNP]
  wide <- dcast(miss_res[SNP %in% top_snps],
                SNP ~ file,
                value.var = c("A1","A2"),
                fun.aggregate = function(x) paste(unique(x), collapse="|"))
  cat("\n--- Esempio (primi 10 SNP, alleli per file) ---\n")
  print(wide)
} else {
  cat("\n(Nessun missnp fornito: per confronto alleli, passa anche il path del final-merge.missnp)\n")
}

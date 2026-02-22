# COSE DA FINIRE 


require(tidyverse)
require(data.table)
require(readxl)



BASE_DIR = "/mnt/user_data/enrico/Genotipi/Neogen100k/Scarichi"
setwd(BASE_DIR)


convert_fam <- function(file) { 

  info <- fread(file) |> as.data.frame()

  # Assegna razze base
  info$Breed <- "NotKnow"
  info$Breed[substr(info$V2, 1, 2) == "07"] <- "Reggiana"
  info$Breed[substr(info$V2, 1, 2) == "06"] <- "Valpadana"
  info$Breed[substr(info$V2, 1, 2) == "10"] <- "Rendena"

  # Leggi file ANAGA
  anaga <- read_excel("../file_addizionali/campioni_ANAGA.xlsx") |> as.data.frame()
  match_idx <- match(anaga$Campione, info$V2)

  #------------------------->  Aggiorna con i campioni ANAGA
  valid_idx <- match_idx[!is.na(match_idx)]
  info$Breed[valid_idx] <- "Grigio"
  info$V2[valid_idx] <- anaga$Matricola[!is.na(match_idx)]

  #------------------------>     Aggiorna i campioni di baganato 

  anaborare <- read_excel("../file_addizionali/Matricole_valdo_PNRR_UNIMI.xlsx") |> as.data.frame()
  match_idx <- match(anaborare$LAB_ID, info$V2)

  # Aggiorna con i campioni ANAGA
  valid_idx <- match_idx[!is.na(match_idx)]
  info$Breed[valid_idx] <- "Valdostana_Unimi"
  info$V2[valid_idx] <- anaborare$Matricola[!is.na(match_idx)]

  # Razza Valdostana
  info$Breed[info$Breed == "NotKnow" & substr(info$V2, 1, 2) == "IT"] <- "Valdostana"

  # Salva FAM modificato
  file.rename(file, "tmp")
  info$V1 <- info$Breed
  fwrite(info[, -ncol(info)], file = file, sep = " ", quote = FALSE, col.names = FALSE)
  unlink("tmp")

  # Ricostruisci file PLINK
  map <- gsub(".fam", "", file)
  system(paste("plink --cow --bfile", map, "--make-bed --out jj > log 2>&1"))
  jj_files <- list.files(pattern = "^jj\\.")
  file.rename(jj_files, sub("^jj", map, jj_files))
}




#-------------------------------------------
# LOOP PRINCIPALE
#-------------------------------------------


# Colori terminale
GREEN  <- "\033[1;32m"
YELLOW <- "\033[1;33m"
RED    <- "\033[1;31m"
RESET  <- "\033[0m"


# Funzione controllo e pulizia PED
check_ped_integrity <- function(ped_file) {
  require(data.table)
  map_file = paste0(ped_file,".map")

  if (!file.exists(map_file)) {
    stop("No corresponding .map file found for: ", ped_file)
  }

  # Count expected number of columns
  n_map <- nrow(fread(map_file, header = FALSE))
  n_expected <- 6 + 2 * n_map

  message("Expected columns in PED: ", n_expected)

  # Define output filenames
  new_ped  =  paste0(ped_file,"_clean.ped")
  bad_rows = paste0(ped_file, "_badrows.txt")
  new_map  =  paste0(ped_file, "_clean.map")
  over_ids = paste0(ped_file, "_overcols_ids.txt")

  # Create cleaned PED with only correct rows
  cmd <- sprintf(
    "awk 'NF == %d {print $0} NF != %d {print NR > \"%s\"}' %s > %s",
    n_expected, n_expected, bad_rows, shQuote(paste0(ped_file,".ped")), shQuote(new_ped)
  )
  system(cmd)

  # Collect IID (second column) for rows having more columns than expected
  cmd_over <- sprintf(
    "awk 'NF > %d {print $2}' %s > %s",
    n_expected, shQuote(paste0(ped_file,".ped")), shQuote(over_ids)
  )
  system(cmd_over)

  # Copy MAP to keep consistency
  file.copy(map_file, new_map, overwrite = TRUE)

  # Report stats
  n_total <- as.integer(system(sprintf("wc -l < %s", shQuote(paste0(ped_file,".ped")) ), intern = TRUE))
  n_good  <- as.integer(system(sprintf("wc -l < %s", shQuote(paste0(ped_file,".ped")) ), intern = TRUE))
  n_bad   <- n_total - n_good

  message("✔ Cleaned PED saved: ", new_ped)
  message("✔ MAP copied as: ", new_map)
  
  if (n_bad > 0) {
    message(" Removed ", n_bad, " malformed lines (saved in ", bad_rows, ")")
  } else {
    message("✅ All rows were correct.")
  }

  # Read overfilled row IDs (matricola/IID) if present
  overfilled_ids <- character(0)
  if (file.exists(over_ids)) {
    overfilled_ids <- readLines(over_ids, warn = FALSE)
    overfilled_ids <- overfilled_ids[nzchar(overfilled_ids)]
  }

  return(list(clean_ped = new_ped, clean_map = new_map, bad = n_bad,
              overfilled_ids = overfilled_ids, overfilled_ids_file = over_ids))
}


# ------------------------------------------
# Loop principale con verifica e color output
# ------------------------------------------
setwd("/mnt/user_data/enrico/Genotipi/Neogen100k/Scarichi")
getwd()


plink_dir <- fread("../resume_plink_info.csv")
plink_dir = plink_dir[!plink_dir$PLINK_dir=="Missing",]
all <- data.frame()
error=data.frame()

getwd()
i=1

for (i in 1:nrow(plink_dir)) {

  cat("\n----------------------------------------\n")
  cat(" Processing:", i, " →", plink_dir[i,][["main_dir"]], "\n")
  cat("----------------------------------------\n")

  main=paste(plink_dir[i,],collapse ="/")
 # system(paste0("ls ",main,"*"))
  success <- FALSE
  cleaned <- FALSE

  tryCatch({

    # Step 1: PLINK ped → bed
    cat("==> Running PLINK conversion...\n")
    system(paste("plink --cow --file", main, "--make-bed --out TMPTMP  > log 2>&1"))
    fixed="no"
    # Se fallisce, controlla integrità PED/MAP
    if (!file.exists("TMPTMP.fam")) {

      
      cat("  ⚠️  PLINK failed — checking PED file integrity...\n")
      res <- check_ped_integrity(main)
    
      cat("  > Retrying PLINK with cleaned PED...\n")
      file <- gsub(".ped$", "", res$clean_ped)
      system(paste("plink --cow --file", file, "--make-bed --out TMPTMP > log 2>&1"))
      
      if (!file.exists("TMPTMP.fam")) stop("Missing TMPTMP.fam even after cleaning")
       fixed="si "
       d=data.frame(id=res$overfilled_ids,ped=res$clean_ped)
       error=rbind(d,error)
    }

    # Step 2: convert fam
    cat("  > Converting .fam ...\n")
    convert_fam("TMPTMP.fam")

    # Step 3: missingness
    cat("  > Running missingness analysis...\n")
    system("plink --cow --bfile TMPTMP --missing > log 2>&1")

    if (!file.exists("plink.imiss"))   stop("Missing plink.imiss after PLINK missingness")

    # Step 4: read results
    tmp = fread("plink.imiss")[, .(FID, IID, F_MISS)]
    tmp[, "fold"] = plink_dir[i,][["main_dir"]]
    tmp[, "fold_fold"] = plink_dir[i,][["PLINK_dir"]]
    tmp[, "file"] = plink_dir[i,][["file_types"]]
    tmp[,"fixed"] = fixed

    all <- rbind(all, tmp, fill = TRUE)
    success <- TRUE

    # Step 5: move TMPTMP files into 'file_sistemati' and rename as baseline
    out_dir <- "../File_Fix/file_sistemati"
    if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
    for (ext in c("bed", "bim", "fam")) {
      src <- paste0("TMPTMP.", ext)
      if (file.exists(src)) {
        dst <- file.path(out_dir, paste0(plink_dir[i,][[2]],"_",plink_dir[i,][[3]], ".", ext))
        file.rename(src, dst)
      }
    }

  }, error = function(e) {
    cat("  ❌ ERROR:", conditionMessage(e), "\n")
  })



  # Esito finale e colore
  if (success && !cleaned) {
    cat(GREEN, "✅ OK tutto bene!\n", RESET)
  } else if (success && cleaned) {
    cat(YELLOW, "⚠️  ATTENZIONE: il PED aveva errori, è stato ripulito e riconvertito.\n", RESET)
  } else {
    cat(RED, "❌ ERRORE: impossibile convertire, file segnato come 'corrupted'\n", RESET)
    tmp <- data.table(
      FID = "file_corrupted",
      IID = "file_corrupted",
      F_MISS = "file_corrupted",
      fold = fold,
      file = file_base
    )
    all <- rbind(all, tmp, fill = TRUE)
  }

  # Pulizia temporanei
  unlink(c("log", "plink*", "SNP_*", "TMPTMP*"), recursive = TRUE)
}

all
all %>% distinct()

# Salva risultati
all[all$fixed=="no","fixed"] = "no"
all[all$fixed=="si ","fixed"] = "si"
fwrite(all, file = "../plink_all_results.csv")

#all %>% group_by(IID) %>% filter(n()>1) %>% View()

cat("\n✅ Analisi completata. Risultati salvati in ../plink_all_results.csv\n")

fold=all %>% select(fold,fold_fold) %>% distinct() %>%
               group_by(fold) %>%  slice_head(n = 1) %>% 
                    ungroup() %>% pluck("fold_fold")

all=as.data.frame(all)
all=all[all$fold_fold %in% fold[-1],]
table(table(all$IID))

fwrite(all, file = "../plink_all_results_nodup.csv")


all_new <- all %>%
  mutate(file = ifelse(fixed == "si", paste0(file, "_clean"),  file))


all_new %>% filter(!fixed=="no")

# Ragruppa in tutte le razze

nomi=names(table(all$FID))
setwd("../")



system("rm -rf File_Fix/Breed")
dir.create("File_Fix/Breed")
getwd()



for(i in nomi ) {  
        dir.create(paste0("File_Fix/Breed/",i)) 
        cat(i,"\n\n\n")
        data.table::fwrite("tmp",x=all[all$FID==i,1:2],sep=" ",quote=FALSE,col.names = TRUE)
        
       
        queste = all[all$FID == i,] %>% 
                  select(fold,fold_fold,file) %>% distinct() %>%  
                                          group_by(fold) %>%  slice_head(n = 1) %>% as.data.frame() %>%
                                                select(fold_fold,file)
        
        folds=apply(queste, 1, function(x) paste(x, collapse = "_"))
        folds=unique(folds)
        
        for (file in folds) {
            cat(file,"\n")
                        
            destination = paste0("File_Fix/Breed/",i,"/",file)
            from = paste0("File_Fix/file_sistemati/",file)
            system(paste("plink --cow --bfile",from,"--keep tmp --make-bed --out ",destination,"> log 2>&1"))
      }
      system("rm tmp log")
      cat("\n\n\n\n\n\n\n")
}



require(tidyverse)
require(data.table)
require(readxl)

source("/home/enrico/Script/FixNeogen/helper/convert_to_ped.R")

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



setwd("/mnt/user_data/enrico/Genotipi/Neogen100k/Scarichi")
final_rep <- fread("../resume_finalreport_info.csv")

all <- data.frame()

out_dir="/mnt/user_data/enrico/Genotipi/Neogen100k/PlinkFromFinalRep"
dir.create(out_dir)  

for (i in 1:nrow(final_rep)) {
  
  id=final_rep[i,][["folder"]]
  cat("\n----------------------------------------\n")
  cat(" Processing:", i, " →", id,"\n")
  cat("----------------------------------------\n")
  
  finaltoplink(input=final_rep[i,3],map=final_rep[i,4],out=paste0(out_dir,"/",id)) # convert fo final rep to plink
  system(paste("plink --cow --file", paste0(out_dir,"/",final_rep[i,1]), "--make-bed --out TMPTMP  >/dev/null  2>&1"))
 
  if (!file.exists("TMPTMP.fam")) { 
         cat("  ⚠️  Error: Need to check",id," ⚠️  \n")
         quit()
  }  


  convert_fam("TMPTMP.fam")
  
  system("plink --cow --bfile TMPTMP --missing > /dev/null  2>&1 ")
  if (!file.exists("plink.imiss"))   {
            cat("⚠️  Missing plink.imiss: ",id)
            quit()
    }

    tmp = fread("plink.imiss")[, .(FID, IID, F_MISS)]
    tmp[, "batch"] = id
    all <- rbind(tmp,all, fill = TRUE)

    for (ext in c("bed", "bim", "fam")) {
      src <- paste0("TMPTMP.", ext)
      if(! file.exists(src)) quit("Qulcosa non va")
      dst <- file.path(out_dir, paste0(id, ".", ext))
      file.rename(src, dst)
     }

}

system("rm log o* plink.* TMPTMP.*")
# rimuvoi i file che mancano

quit()




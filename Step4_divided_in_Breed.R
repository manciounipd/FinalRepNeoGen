
#====================================
# Remove non necessari files 
#====================================

setwd("/mnt/user_data/enrico/Genotipi/Neogen100k/PlinkFromFinalRep")

fam_files <- list.files(path = ".",pattern = "\\.fam$",recursive = TRUE,full.names = TRUE)


all_fam <- purrr::map_dfr(fam_files, function(f) {
  x <- read.table( f, header = FALSE, stringsAsFactors = FALSE,col.names = c("FID", "IID", "PID", "MID", "SEX", "PHENO"))
  x$source_file <- gsub("./","",gsub(".fam","",f))
  x
})



files_plink =  gsub("./","",gsub(".fam","",fam_files))

# Faccio anche il file del riassunto 
system(" rm -rf Breed")
dir.create("Breed")
getwd()

Breed=unique(all_fam$FID)
i="Rendena"
for(i in Breed) {  
        out_fold=paste0("Breed/",i)
        dir.create(out_fold) 
        
        cat(i,"\n")
        data.table::fwrite("tmp",x=all_fam[all_fam$FID==i,1:2],sep=" ",quote=FALSE,col.names = TRUE)
        
      
        for (file in files_plink) {
             cat("-->",file,"\n")
            destination=paste0(out_fold,"/",file)
            system(paste("plink --cow --bfile", file, "--keep tmp --make-bed --out", destination,"> log &"))
      }
      
      system("rm tmp")
      cat("\n")
}



data.table::fwrite(all_fam[, c("FID", "IID", "source_file")],file = "recap_fam.tsv",sep = "\t",quote = FALSE,col.names = TRUE)



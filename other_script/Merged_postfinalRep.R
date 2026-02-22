
require(tidyverse)
load(paste0("RData/info_2025-09-24.RData"))
ls()

dir.create("merged_plink")
system("plink --cow  --merge-list  per_plink.txt  --recode   --out merged_plink/merged")
system("plink --cow  --merge-list  per_plink.txt  --make-bed --out merged_plink/merged")


informazioni_df=do.call("rbind",info)
row.names(informazioni)=1:nrow(informazioni)

informazioni_df %>% group_by(dir) %>% summarize(n=length(unique(file)))


nomi_=data.frame(file=informazioni_df$file,fold=informazioni_df$dir,
                  nomi=informazioni_df$nomi,Breed="Unknow")

# uso questo metot per clasfficare le varie razze
nomi_[substr(nomi_$nomi, 1, 2) == "07","Breed"]="Reggiana"
nomi_[substr(nomi_$nomi, 1, 2) == "06" ,"Breed"]="Valpadana"
nomi_[substr(nomi_$nomi, 1, 2) == "10" ,"Breed"]="Rendena"

# ----> i grigi invce hanno un altro codice <----#
anaga=as.data.frame(readxl::read_excel("file_addizionali/campioni_ANAGA.xlsx"))
nomi_[nomi_$nomi %in% anaga$Campione,"Breed"] = "Grigio"

# ---> per i valostani utilizza il pedigree
valdo=data.table::fread("file_addizionali/animali_valdo_in_ana.txt");names(valdo)="a"
nomi_[nomi_$nomi %in% valdo$a,"Breed"]="Valdostana" # cambia i sconosciuti in Valdostana

# create final fam
setwd("merged_plink")

cat("different row() becouse fiels has 3 duplicate id, plink outmatically remove it \n")

fam=data.table::fread("merged.fam")
updt=nomi_[,c(3,4)]
fam[,"V1"]=updt[match(fam$V2,updt$nomi),"Breed"]
system("mv merged.fam merged_save.fam")             # mi salvo il file originale per sicurezza nel caso facessi casino
data.table::fwrite(file="merged.fam",fam,sep=" ",quote=FALSE)



###################
#  fo prove est



# fai una porova estrendo la regfiana
writeLines(text="Reggiana\nValpadana",con="breed_extract")
system("plink --cow --bfile  merged_plink/merged  --keep-fam breed_extract --make-bed --out merged_plink/Reggiana")

## per la grigio poi fai il merge con le marticole

goto=nomi_[nomi_$Breed=="Reggiana",] %>% count(fold) 
fread(paste0(goto$fold[1],"/",goto$fold[1],"_Final_Report.txt"),sep="")



fread("University_of_Padova-Roberto_Mantovani_BOVG100V1_20250801/University_of_Padova-Roberto_Mantovani_BOVG100V1_20250801_FinalReport.txt",sep="")


nomi_ %>% filter(fold=="University_of_Padova-Roberto Mantovani_BOVG100V1_20250801")

system("rclone copy University_of_Padova-Roberto_Mantovani_AYR_BOVG100V1_20250811  EnricoUnipd/Genotipi_Neogen_Reggiana -P")

system("rclone ls EnricoUnipd/Genotipi_Neogen_Reggiana")
system("rclone config")

GTWD=getwd()

nomi_[nomi_$Breed=="Valpadana",] %>% count(fold)



folds <- nomi_[nomi_$Breed=="Reggiana",] %>% count(fold) %>% pluck("fold")

nomi_ %>% filter(fold  %in% folds) %>% count(fold)



for(i in folds) {
  cat(i, "\n")
  
  # Percorso locale e percorso su Drive con virgolette
  local_path <- paste0("\"", GTWD, "/", i, "\"")
  remote_path <- paste0("\"EnricoUnipd:Genotipi_Neogen_Reggiana/", i, "\"")
  
  cmd <- paste("rclone copy -P", local_path, remote_path)
  
  cat("Running command:\n", cmd, "\n")
  system(cmd)
}
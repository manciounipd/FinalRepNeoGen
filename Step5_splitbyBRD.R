require("data.table")
require("tidyverse")

info = as.data.frame(fread("called_all_data_megred/merged_all_data.fam"))

info$Breed = "NotKnow"
info[substr(info$V2, 1, 2) == "07","Breed"]="Reggiana"
info[substr(info$V2, 1, 2) == "06" ,"Breed"]="Valpadana"
info[substr(info$V2, 1, 2) == "10" ,"Breed"]="Rendena"


anaga=as.data.frame(readxl::read_excel("file_addizionali/campioni_ANAGA.xlsx"))
info[info$V2 %in% anaga$Campione,"Breed"] = "Grigio"

info[info$Breed=="NotKnow" & substr(info$V2, 1, 2) == "IT" ,"Breed"] = "Valdostana"
table(info$Breed)
#View(info[info$Breed=="NotKnow",])

system("mv called_all_data_megred/merged_all_data.fam called_all_data_megred/tmp")
info$V1=info$Breed
data.table::fwrite(file="called_all_data_megred/merged_all_data.fam",info[,-ncol(info)],sep=" ",quote=FALSE)


breed=names(table(info$Breed))

for( i in breed) {}
dir.create(paste0("called_all_data_megred/",i))
fwrite(file="tmp",x=info[info$V1==i,c("V1","V2")],,sep=" ",quote=FALSE,col.names = TRUE)
system("plink --cow --bfile called_all_data_megred/merged_all_data --keep tmp --make-bed --out called_all_data_megred")

system("plink --cow --bfile called_all_data_megred/merged_all_data --recode 12  --out called_all_data_megred/k")


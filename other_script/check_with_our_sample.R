
sample_info=all %>% select(FID,IID,F_MISS) %>% distinct()

# gaurda quanti campioni mancano
anaga <- read_excel("../file_addizionali/campioni_ANAGA.xlsx") |> as.data.frame()
anaga[!anaga$Matricola %in% sample_info$IID,] # grgio alpini che mancano

tmp=list()
sheet_names = excel_sheets("../file_addizionali/Rendena.xlsx")
for(x in sheet_names) tmp[[x]] = data.frame(read_excel("../file_addizionali/Rendena.xlsx",sheet = x),scatola=x)

anare=do.call(rbind,tmp) 
nrow(anare)

names(anare)=c("ID","Matricola","scatola")
anare=anare%>% filter(!is.na(Matricola))
anare[!anare$Matricola %in% sample_info$IID,]


tmp=list()
sheet_names = excel_sheets("../file_addizionali/Valdostana.xlsx")
for(x in sheet_names) tmp[[x]] = data.frame(read_excel("../file_addizionali/Valdostana.xlsx",sheet = x),scatola=x)
anaborare=do.call("rbind",tmp)
row.names(anaborare)=1:nrow(anaborare)

anaborare[!anaborare$ANIMALID %in% sample_info$IID  & grepl("^IT", anaborare$ANIMALID),]


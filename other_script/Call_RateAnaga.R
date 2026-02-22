anaga=as.data.frame(readxl::read_excel("file_addizionali/campioni_ANAGA.xlsx"))
mio=data.table::fread("callrate_list.csv")

head(mio)
head(anaga)

require("tidyverse")
ALL=merge(anaga,mio,by.x="Campione",by.y="animal_id",all.x=TRUE)
ALL %>% filter(!is.na(call_rate))


cor(ALL[["Call rate"]],ALL[["call_rate"]])


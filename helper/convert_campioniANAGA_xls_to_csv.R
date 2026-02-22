#!/usr/bin/env Rscript

input_file <- "/mnt/user_data/enrico/Genotipi/Neogen100k/file_addizionali/campioni_ANAGA.xlsx"
output_file <- "/mnt/user_data/enrico/Genotipi/Neogen100k/file_addizionali/campioni_ANAGA.csv"

df <- readxl::read_excel(input_file)
utils::write.table(df[,c(1,10)],file = output_file,sep = ";",row.names = FALSE,col.names = TRUE,quote = FALSE,na = "")

cat("Written:", output_file, "\n")

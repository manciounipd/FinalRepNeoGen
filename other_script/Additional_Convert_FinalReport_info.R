# form negen 
system("unzip University\ of\ Padova-Roberto\ Mantovani.zip")

require(data.table)
source("Script/convert_to_ped.R")

lista=list.dirs(path = ".",full.names=FALSE, recursive=FALSE)
files=grep("Univ",lista,value= TRUE)
per_plink=list()
info=list()
x=1

for (dir in files) {
  setwd(dir)

  ReportFile_zip=grep("FinalReport.zip", list.files(), value = TRUE)

  if (length(ReportFile_zip) > 0) {

    Map_zip=grep("SNP_Map.zip", list.files(), value = TRUE)
    
    cat("Extracting files ...\n")

    for (i in ReportFile_zip) { unzip(i, overwrite = FALSE)}
    for (i in Map_zip) { unzip(i, overwrite = FALSE)}

    # there may be one map and several report files
    ReportFile = grep("FinalReport.txt", list.files(), value = TRUE)
    Map        = grep("SNP_Map.txt",     list.files(), value = TRUE)

    if (length(ReportFile) > 0) {

      for (rf in ReportFile) {
        nome = sub("_FinalReport.txt$", "", rf)
        nome = gsub(" ", "_", nome)   # replace spaces with underscore
        # conta se ci sono poi report per folder 

        # convert
        get_ped(input = rf, map = Map, outname = nome)
        # cleanup intermediates created by get_ped based on the map filename
        map_prefix <- gsub("[^A-Za-z0-9._-]", "_", sub("\\.[^.]+$", "", basename(Map[1])))
        system(paste("rm -f", paste(paste0(map_prefix, c(".fam", ".lgen", ".map")), collapse = " ")))

        # look at the IDs (quote path to handle spaces)
        ped_file = sprintf("'%s.ped'", nome)
        id = system(sprintf("awk '{print $2}' %s", ped_file), intern = TRUE)

        info[[rf]] = data.frame(nomi = id, file = rf, dir = dir)

        add = file.path(dir, nome)
        per_plink[[rf]] = data.frame(
          ped = paste0(add, ".ped"),
          map = paste0(add, ".map")
        )
      }
    } else {
      cat("NO FILE REPORT\n")
    }
  }

  setwd("..")
}




getwd()
system("chmod 775 ./Script/replce_space_with_.sh")
system("./Script/replce_space_with_.sh")


per_plink_df=do.call("rbind",per_plink)
row.names(per_plink)=1:nrow(per_plink_df)

file=data.frame(ped=per_plink_df[1,],map=per_plink_df[2,])
file$ped=gsub(" ","_",file$ped)
file$map=gsub(" ","_",file$map)

fwrite(file,"per_plink.txt",sep=" ",quote=FALSE,col.names=FALSE)
# Merged in plink

dir.create("RData")
save.image(paste0("RData/info_",Sys.Date() ,".RData"))


## fino a qua ###





#

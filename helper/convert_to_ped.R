

finaltoplink=function(input,map,out) {
    
    require(tidyverse)
    require(data.table)
    input=as.character(input)
    out=as.character(out)
    map=as.character(map)
    
    cat("Using delimiter outodetection of fread\n")
    
    tmp=fread(input,skip = 9, header = TRUE) 
    
    #=================================================================================#
    # Punto critico cambia ==> se c'è spazio metti _ perche fa un casino boia !
    #================================================================================#

    tmp <- tmp %>%
      mutate(across(
        any_of(c("Sample ID or SNP name", "Sample ID", "SNP Name")),
        ~ gsub(" ", "_", as.character(.x))
      ))
    #print(tmp[1,])
    # Map file
    SNP=fread(map)

    # Build a safe prefix based on the provided map filename
    # Use the basename without extension, sanitize to avoid spaces/special chars

    map_prefix <- sub("\\.[^.]+$", "", basename(map))
    map_prefix <- gsub("[^A-Za-z0-9._-]", "_", map_prefix)

    # Fam file
    tmp %>%
    distinct(`Sample ID`) %>%
    mutate(FID = "BTAU", sire = 0, dam = 0, sex = 0, phenotype = -9) %>%
    relocate(`Sample ID`, .after = FID) %>%
    write_delim(paste0(map_prefix, ".fam"), col_names = F)

    # Lgen file
    tmp %>%
    mutate(FID = "BTAU") %>%
    select(FID, `Sample ID`, `SNP Name`, `Allele1 - AB`, `Allele2 - AB`) %>%
    write_delim(paste0(map_prefix, ".lgen"), col_names = F)

    # Map file
    SNP  %>%
    mutate(morgan = 0) %>%
    dplyr::select(Chromosome, Name, morgan, Position) %>%
    write_delim(paste0(map_prefix, ".map"), col_names = F)

    # change to ped file with PLINK 
    system(paste0(
      "plink --cow --nonfounders --allow-no-sex --lfile ",
      map_prefix,
      " --missing-genotype - --output-missing-genotype 0 --recode --out ",
      out  ," >  /dev/null  2>&1"
    ))

    system("rm SNP_Map.*")

    cat("conversione don3\n")
}


#setwd("~/GENOTIPI/GENOTIPI_GRIGIO/DATA/rossoni")

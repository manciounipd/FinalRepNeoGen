#!/bin/bash 

DSCRIPT="/home/enrico/Script/FixNeogen"
DWORK="/mnt/user_data/enrico/Genotipi/Neogen100k"

cd $DWORK

bash ${DSCRIPT}"/Step1_Rename_Extract_Rename.sh"
 
Rscript ${DSCRIPT}"/Step2_check_final_report.R"

Rscript ${DSCRIPT}"/Step3_nuovo.R"

Rscript ${DSCRIPT}"/Step4_divided_in_Breed.R"

bash ${DSCRIPT}"/Step5_mergia_all.sh"

# JUST SCHECK
wc  -l   PlinkFromFinalRep/Breed/*/merged/*.fam

bash ${DSCRIPT}/Step6_buono_Extract_breed_final_report.sh

echo "Check in ${DWORK} the file plink_all_results.csv" 

#==============================>
# Invia i ifles: 
#===========================>

# Invio a Reggiana 
rclone copy merged_plink "EnricoUnipd:Genotipi_Neogen_Reggiana" --include "Reggiana*"

# se modifico qualcosa, aggiorno anche su GitHub
bash ${DSCRIPT}/uploadgit.sh
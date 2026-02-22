#!/bin/bash
set -euo pipefail

DIR="/mnt/user_data/enrico/Genotipi/Neogen100k/"
cd $DIR

breeds=$( ls PlinkFromFinalRep/Breed/)
all_files=$(ls Scarichi/Univ*/*FinalReport.txt)
conversione="/mnt/user_data/enrico/Genotipi/Neogen100k/file_addizionali/campioni_ANAGA.csv"

for brd in $breeds
do
    echo "--------------   "${brd}"  --------------"
    mkdir -p "Breed_Final_Report/"${brd}
    echo " Per ogni aniamale della razza  "${brd}":"

    awk  '{print $2}' PlinkFromFinalRep/Breed/${brd}/*.fam  > ids.txt
    # se c'è la grigio cambia perche mancano gli id !

    if [[ "$brd" == "Grigio" ]]; then
       echo "converti grigio.."
       join -t ';' -1 1 -2 1 \
         <(awk -F ';' 'NR>1 {print $1";"$2}' "$conversione" | sort -t ';' -k1,1) \
         <(sort -k1,1 ids.txt) | \
         awk -F ';' '{print $2}'  > tmp
         rm ids.txt
         mv tmp ids.txt
    fi
    # per tutti ifiles 
    printf '%s\n' "$all_files" | while IFS= read -r DATA_FILE; do

            # echo $DATA_FILE
                OldDir="$(dirname "$DATA_FILE")"
                #echo $DATA_FILE
                echo "Cerca in "$OldDir

                BASE="$(basename "$DATA_FILE")"
                tmp="${BASE%"_FinalReport.txt"}"            

                OUTPUT_FILE_1="Breed_Final_Report/${brd}/"$tmp"FinalReport.txt"
                OUTPUT_FILE_2="Breed_Final_Report/${brd}/"$tmp"DNAReport.csv"

                # Count matches from line 6 to end
                MATCH_COUNT=$(
                  awk '
                    FNR==NR { ids[$1]=1; next }
                    ($2 in ids) { seen[$2]=1 }
                    END {
                      c=0
                      for (k in seen) c++
                      print c
                    }
                  ' ids.txt <(tail -n +6 "$DATA_FILE")
                )
                echo "Numero di animali presenti "$MATCH_COUNT

                if [ "$MATCH_COUNT" -gt 0 ]; then
                    
                    # Extract first 7 lines
                    head -n 10 "$DATA_FILE" > "$OUTPUT_FILE_1"
                    # Append lines matching IDs from line 6 onwards
                    awk '
                      FNR==NR { ids[$1]=1; next }
                      ($2 in ids)
                    ' ids.txt <(tail -n +10 "$DATA_FILE") >> "$OUTPUT_FILE_1"
                    
                    
                    # anche dna report
                    # se c0è ed zip estrirlo , senno non che propio esci 
                    tmpx="${DATA_FILE/FinalReport.txt/DNAReport.csv}"
                    if [ ! -f "$tmpx" ]; then
                      zipx="${DATA_FILE/FinalReport.txt/DNAReport.zip}"
                      if [ -f "$zipx" ]; then
                        echo "Estraggo DNAReport da zip: $zipx"
                        unzip -o "$zipx" -d "$OldDir" >/dev/null
                      fi
                    fi
                    if [ ! -f "$tmpx" ]; then
                      alt_csv="$(find "$OldDir" -maxdepth 1 -type f -name '*DNAReport.csv' | head -n 1)"
                      if [ -n "$alt_csv" ]; then
                        tmpx="$alt_csv"
                      fi
                    fi

                    if [ -f "$tmpx" ]; then
                      # Then process your new file
                      head -n 3 "$tmpx" >> "$OUTPUT_FILE_2"
                      awk '
                        FNR==NR { ids[$1]=1; next }
                        ($2 in ids)
                      ' ids.txt <(tail -n +4 "$tmpx") >> "$OUTPUT_FILE_2"
                    else
                      echo "ERRORE: DNAReport.csv mancante in $OldDir e non estraibile da zip"
                      exit 1
                    fi

                # copia anche la mappa (estrai da zip se manca txt)
                    snp_map_txt="$OldDir/SNP_Map.txt"
                    snp_map_zip="$OldDir/SNP_Map.zip"
                    if [ ! -f "$snp_map_txt" ] && [ -f "$snp_map_zip" ]; then
                      echo "Estraggo SNP_Map da zip: $snp_map_zip"
                      unzip -o "$snp_map_zip" -d "$OldDir" >/dev/null
                    fi
                    if [ ! -f "$snp_map_txt" ]; then
                      echo "ERRORE: SNP_Map.txt mancante in $OldDir e non estraibile da zip"
                      exit 1
                    fi
                    cp "$snp_map_txt" "Breed_Final_Report/${brd}/"$tmp"_SnpMap.txt"
                else
                    echo "No ghe ze nulla"
                fi
     echo "#####################################"
    done
    rm ids.txt
done


